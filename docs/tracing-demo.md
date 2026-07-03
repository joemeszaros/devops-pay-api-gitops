# Jaeger tracing demó

Ez a demó a `pay-api` szolgáltatás OpenTelemetry trace-jeit a klaszteren belüli Jaeger példányba küldi OTLP/HTTP protokollon.

## Telepített elemek

- `pay-api` alkalmazás `OTEL_*` környezeti változókkal
- `jaeger` all-in-one példány az `observability` namespace-ben
- Argo CD alkalmazás: `jaeger`

## Alkalmazások szinkronizálása

```bash
kubectl apply -f clusters/prod/jaeger-application.yaml
kubectl apply -f clusters/prod/pay-api-prod-application.yaml
```

## Állapot ellenőrzése

```bash
kubectl get application -n argocd
kubectl get pods -n observability
kubectl get pods -n pay-api-prod
```

## Elérés port-forwarddal

Jaeger UI:

```bash
kubectl port-forward svc/jaeger -n observability 16686:16686
```

`pay-api`:

```bash
kubectl port-forward svc/pay-api -n pay-api-prod 8080:80
```

## Példa API-hívás

```bash
curl -i \
  -X POST http://127.0.0.1:8080/payments/quote \
  -H 'content-type: application/json' \
  -d '{"amountMinor":15001,"currency":"HUF","installments":6}'
```

Várt eredmény:

- `200 OK`
- válasz JSON részletfizetési ajánlattal
- `x-trace-id` fejléc

## Trace megnyitása Jaegerben

1. Nyisd meg: `http://127.0.0.1:16686`
2. Szolgáltatás: `pay-api`
3. A legfrissebb trace-ek között látszódni fog a kérés

Ha a `curl` válaszban megkaptad az `x-trace-id` fejlécet, közvetlenül is megnyithatod:

```text
http://127.0.0.1:16686/trace/<x-trace-id>
```

## Mit érdemes látni a trace-ben

- a bejövő HTTP kérés spanje
- a kézi `quote.calculate` span
- a span attribútumai:
  - összeg
  - pénznem
  - részletszám
  - quote azonosító

Később, amikor a `pay-api` meghív egy másik mikroszolgáltatást, ugyanebben a trace-ben meg fognak jelenni a kliens- és szerveroldali spanek is.
