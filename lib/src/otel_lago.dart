// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry_api/dartastic_opentelemetry_api.dart';

import 'otel_lago_suppression.dart';

const _tracerName = 'dartastic_otel_libs_lago';

APITracer _tracer() => OTelAPI.tracerProvider().getTracer(_tracerName);

class LagoResult {
  /// Creates a result.
  const LagoResult({
    this.organizationId,
    this.entityKind,
    this.entityId,
    this.externalCustomerId,
    this.subscriptionExternalId,
    this.subscriptionStatus,
    this.planCode,
    this.billableMetricCode,
    this.aggregationType,
    this.eventTransactionId,
    this.batchSize,
    this.acceptedEvents,
    this.rejectedEvents,
    this.invoiceNumber,
    this.invoiceStatus,
    this.amountCents,
    this.currency,
    this.statusCode,
  });

  /// Lago organization (multi-tenant for self-host + Cloud).
  final String? organizationId;

  /// `customer` / `subscription` / `plan` / `billable_metric` /
  /// `event` / `invoice` / `credit_note` / `add_on` / `coupon` /
  /// `wallet` / `applied_coupon`.
  final String? entityKind;

  final String? entityId;

  /// Customer's own id (Lago's `external_customer_id`).
  final String? externalCustomerId;

  final String? subscriptionExternalId;

  /// `pending` / `active` / `terminated` / `canceled`.
  final String? subscriptionStatus;

  final String? planCode;

  /// Billable metric being recorded against (`api_calls`,
  /// `compute_minutes`, `gb_stored`, etc.).
  final String? billableMetricCode;

  /// `count_agg` / `sum_agg` / `max_agg` / `unique_count_agg` /
  /// `latest_agg` / `weighted_sum_agg` / `custom_agg`.
  final String? aggregationType;

  final String? eventTransactionId;

  /// Number of events submitted in `events.create_batch`.
  final int? batchSize;

  /// Accepted + rejected event counts (rejected when validation fails
  /// or duplicate transaction_id is sent).
  final int? acceptedEvents;
  final int? rejectedEvents;

  final String? invoiceNumber;

  /// `draft` / `finalized` / `voided` / `pending`.
  final String? invoiceStatus;

  /// Invoice total in minor units.
  final int? amountCents;

  final String? currency;

  final int? statusCode;
}

/// What a traced call returned: the value for the caller plus fields
/// recorded on the span.
class LagoCallResult<T> {
  /// Creates a call result.
  const LagoCallResult({required this.value, this.result});

  /// The value returned to the caller.
  final T value;
  final LagoResult? result;
}

/// Wraps a Lago API call in a CLIENT span. [operation] is one of
/// `events.create`, `events.create_batch`, `events.estimate_fees`,
/// `customers.create`, `customers.update`, `customers.usage`,
/// `subscriptions.create`, `subscriptions.terminate`,
/// `plans.create`, `billable_metrics.create`, `invoices.list`,
/// `invoices.refresh`, `invoices.finalize`, `invoices.void`,
/// `add_ons.apply`, `coupons.apply`, `wallets.create`.
Future<T> tracedLago<T>({
  required String operation,
  required Future<LagoCallResult<T>> Function() invoke,
}) async {
  if (lagoInstrumentationSuppressed()) {
    final r = await invoke();
    return r.value;
  }
  final m = <String, Object>{
    'rpc.system': 'lago',
    'rpc.method': operation,
    'lago.operation': operation,
  };

  final span = _tracer().startSpan(
    'lago $operation',
    kind: SpanKind.client,
    attributes: OTelAPI.attributesFromMap(m),
  );
  try {
    final r = await invoke();
    if (r.result != null) {
      final extras = <Attribute<Object>>[];
      if (r.result!.organizationId != null) {
        extras.add(OTelAPI.attributeString(
          'lago.organization.id',
          r.result!.organizationId!,
        ));
      }
      if (r.result!.entityKind != null) {
        extras.add(OTelAPI.attributeString(
          'lago.entity.kind',
          r.result!.entityKind!,
        ));
      }
      if (r.result!.entityId != null) {
        extras.add(OTelAPI.attributeString(
          'lago.entity.id',
          r.result!.entityId!,
        ));
      }
      if (r.result!.externalCustomerId != null) {
        extras.add(OTelAPI.attributeString(
          'lago.customer.external_id',
          r.result!.externalCustomerId!,
        ));
      }
      if (r.result!.subscriptionExternalId != null) {
        extras.add(OTelAPI.attributeString(
          'lago.subscription.external_id',
          r.result!.subscriptionExternalId!,
        ));
      }
      if (r.result!.subscriptionStatus != null) {
        extras.add(OTelAPI.attributeString(
          'lago.subscription.status',
          r.result!.subscriptionStatus!,
        ));
      }
      if (r.result!.planCode != null) {
        extras.add(OTelAPI.attributeString(
          'lago.plan.code',
          r.result!.planCode!,
        ));
      }
      if (r.result!.billableMetricCode != null) {
        extras.add(OTelAPI.attributeString(
          'lago.billable_metric.code',
          r.result!.billableMetricCode!,
        ));
      }
      if (r.result!.aggregationType != null) {
        extras.add(OTelAPI.attributeString(
          'lago.billable_metric.aggregation_type',
          r.result!.aggregationType!,
        ));
      }
      if (r.result!.eventTransactionId != null) {
        extras.add(OTelAPI.attributeString(
          'lago.event.transaction_id',
          r.result!.eventTransactionId!,
        ));
      }
      if (r.result!.batchSize != null) {
        extras.add(OTelAPI.attributeInt(
          'lago.batch.size',
          r.result!.batchSize!,
        ));
      }
      if (r.result!.acceptedEvents != null) {
        extras.add(OTelAPI.attributeInt(
          'lago.events.accepted',
          r.result!.acceptedEvents!,
        ));
      }
      if (r.result!.rejectedEvents != null) {
        extras.add(OTelAPI.attributeInt(
          'lago.events.rejected',
          r.result!.rejectedEvents!,
        ));
        if (r.result!.rejectedEvents! > 0 &&
            r.result!.acceptedEvents != null &&
            r.result!.acceptedEvents == 0) {
          span.setStatus(
            SpanStatusCode.Error,
            'Lago batch all-rejected',
          );
        }
      }
      if (r.result!.invoiceNumber != null) {
        extras.add(OTelAPI.attributeString(
          'lago.invoice.number',
          r.result!.invoiceNumber!,
        ));
      }
      if (r.result!.invoiceStatus != null) {
        extras.add(OTelAPI.attributeString(
          'lago.invoice.status',
          r.result!.invoiceStatus!,
        ));
      }
      if (r.result!.amountCents != null) {
        extras.add(OTelAPI.attributeInt(
          'lago.amount.cents',
          r.result!.amountCents!,
        ));
      }
      if (r.result!.currency != null) {
        extras.add(OTelAPI.attributeString(
          'lago.currency',
          r.result!.currency!,
        ));
      }
      if (r.result!.statusCode != null) {
        extras.add(OTelAPI.attributeInt(
          'http.response.status_code',
          r.result!.statusCode!,
        ));
        if (r.result!.statusCode! >= 400) {
          span.setStatus(
            SpanStatusCode.Error,
            'Lago HTTP ${r.result!.statusCode}',
          );
        }
      }
      if (extras.isNotEmpty) span.addAttributes(OTelAPI.attributes(extras));
    }
    return r.value;
  } catch (e, st) {
    span.addAttributes(OTelAPI.attributes([
      OTelAPI.attributeString(
        ErrorAttributes.errorType.key,
        e.runtimeType.toString(),
      ),
    ]));
    span.recordException(e, stackTrace: st);
    span.setStatus(SpanStatusCode.Error, e.toString());
    rethrow;
  } finally {
    span.end();
  }
}
