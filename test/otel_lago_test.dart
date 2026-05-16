// Licensed under the Apache License, Version 2.0
// Copyright 2025, Mindful Software LLC, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:dartastic_opentelemetry/testing.dart';
import 'package:otel_lago/otel_lago.dart';
import 'package:test/test.dart';

void main() {
  late TestHarness harness;
  late InMemorySpanExporter spans;

  setUpAll(() async {
    harness = await maybeInitializeOtelForTest(
      serviceName: 'otel_lago-test',
    );
    spans = harness.spans;
  });

  setUp(() => harness.clear());

  Map<String, Object> attrsOf(Span s) =>
      {for (final a in s.attributes.toList()) a.key: a.value};

  test('events.create_batch records BM + accepted/rejected', () async {
    await tracedLago<String>(
      operation: 'events.create_batch',
      invoke: () async => const LagoCallResult(
        value: 'ok',
        result: LagoResult(
          organizationId: 'org_1',
          externalCustomerId: 'cust_abc',
          billableMetricCode: 'api_calls',
          aggregationType: 'sum_agg',
          batchSize: 500,
          acceptedEvents: 498,
          rejectedEvents: 2,
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('lago events.create_batch')!);
    expect(a['lago.billable_metric.code'], 'api_calls');
    expect(a['lago.billable_metric.aggregation_type'], 'sum_agg');
    expect(a['lago.events.accepted'], 498);
    expect(a['lago.events.rejected'], 2);
  });

  test('all-rejected batch sets span error', () async {
    await tracedLago<String>(
      operation: 'events.create_batch',
      invoke: () async => const LagoCallResult(
        value: 'ok',
        result: LagoResult(
          batchSize: 100,
          acceptedEvents: 0,
          rejectedEvents: 100,
        ),
      ),
    );
    expect(
      spans.findSpanByName('lago events.create_batch')!.status,
      SpanStatusCode.Error,
    );
  });

  test('invoices.finalize records number + status + amount', () async {
    await tracedLago<String>(
      operation: 'invoices.finalize',
      invoke: () async => const LagoCallResult(
        value: 'ok',
        result: LagoResult(
          invoiceNumber: 'LAGO-2026-0001',
          invoiceStatus: 'finalized',
          amountCents: 425000,
          currency: 'USD',
          statusCode: 200,
        ),
      ),
    );
    final a = attrsOf(spans.findSpanByName('lago invoices.finalize')!);
    expect(a['lago.invoice.number'], 'LAGO-2026-0001');
    expect(a['lago.invoice.status'], 'finalized');
    expect(a['lago.amount.cents'], 425000);
    expect(a['lago.currency'], 'USD');
  });

  test('subscriptions.terminate captures status without span error', () async {
    await tracedLago<String>(
      operation: 'subscriptions.terminate',
      invoke: () async => const LagoCallResult(
        value: 'ok',
        result: LagoResult(
          subscriptionExternalId: 'sub_1',
          subscriptionStatus: 'terminated',
          planCode: 'pro_monthly',
        ),
      ),
    );
    expect(
      spans.findSpanByName('lago subscriptions.terminate')!.status,
      isNot(SpanStatusCode.Error),
    );
  });

  test('suppression skips spans', () async {
    await runWithoutLagoInstrumentationAsync(() async {
      await tracedLago<String>(
        operation: 'customers.usage',
        invoke: () async => const LagoCallResult(value: 'v'),
      );
    });
    expect(spans.findSpansStartingWith('lago '), isEmpty);
  });
}
