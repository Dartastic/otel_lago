// Licensed under the Apache License, Version 2.0
// Copyright 2025-2026 Mindful Software LLC d/b/a Dartastic.io, All rights reserved.

import 'package:dartastic_opentelemetry/dartastic_opentelemetry.dart';
import 'package:otel_lago/otel_lago.dart';

/// Traces Lago calls with OpenTelemetry.
///
/// `otel_lago` depends on the OpenTelemetry API only, so the application
/// initializes an SDK once at startup. Wrap each Lago call in
/// [tracedLago]; the `invoke` callback makes the real call and reports what
/// came back, which is recorded on the span.
Future<void> main() async {
  await OTel.initialize(serviceName: 'lago-example');

  // Wraps a Lago API call in a CLIENT span.
  final lagoId = await tracedLago<String>(
    operation: 'events.create',
    invoke: () async {
      // Make the Lago call here, then report what it returned.
      const id = 'lago_8f3a2c';
      return const LagoCallResult(
          value: id,
          result: LagoResult(
              organizationId: 'organization_8f3a2c',
              entityKind: 'customer',
              entityId: 'entity_8f3a2c',
              externalCustomerId: 'external_customer_id',
              subscriptionExternalId: 'subscriptionexternal_8f3a2c',
              subscriptionStatus: 'pending',
              planCode: 'example',
              billableMetricCode: 'api_calls',
              aggregationType: 'count_agg',
              eventTransactionId: 'eventtransaction_8f3a2c',
              batchSize: 512,
              acceptedEvents: 1,
              rejectedEvents: 1,
              invoiceNumber: 'example',
              invoiceStatus: 'draft',
              amountCents: 1999,
              currency: 'usd',
              statusCode: 201));
    },
  );
  OTelLog.info('tracedLago events.create returned $lagoId');

  // Calls that should not be traced, such as health checks, run inside
  // runWithoutLagoInstrumentationAsync.
  await runWithoutLagoInstrumentationAsync(
    () => tracedLago<String>(
      operation: 'events.create',
      invoke: () async {
        const id = 'lago_8f3a2c';
        return const LagoCallResult(
            value: id,
            result: LagoResult(
                organizationId: 'organization_8f3a2c',
                entityKind: 'customer',
                entityId: 'entity_8f3a2c',
                externalCustomerId: 'external_customer_id',
                subscriptionExternalId: 'subscriptionexternal_8f3a2c',
                subscriptionStatus: 'pending',
                planCode: 'example',
                billableMetricCode: 'api_calls',
                aggregationType: 'count_agg',
                eventTransactionId: 'eventtransaction_8f3a2c',
                batchSize: 512,
                acceptedEvents: 1,
                rejectedEvents: 1,
                invoiceNumber: 'example',
                invoiceStatus: 'draft',
                amountCents: 1999,
                currency: 'usd',
                statusCode: 201));
      },
    ),
  );

  await OTel.shutdown();
}
