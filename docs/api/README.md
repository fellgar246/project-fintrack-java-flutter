# FinTrack API examples

## REST Client (VS Code / Cursor)

1. Install the [REST Client](https://marketplace.visualstudio.com/items?itemName=humao.rest-client) extension.
2. Start the API (`docker compose --profile full up` or `./gradlew bootRun` with Postgres).
3. Open [`fintrack.http`](fintrack.http).
4. Run requests top to bottom with **Send Request** (or `Cmd+Alt+R` / `Ctrl+Alt+R`).
5. Named requests (`# @name login`) feed variables like `@token = {{login.response.body.tokens.accessToken}}`.

Run **Register** once on a clean database; on later runs use **Login** only (duplicate register returns 409).

## IntelliJ HTTP Client

Open `fintrack.http` in IntelliJ IDEA or Android Studio. The same `@host`, `@name`, and `{{variable}}` syntax works.

## Postman / Insomnia

Import [`openapi.json`](openapi.json):

```bash
curl -s http://localhost:8080/api/v1/v3/api-docs -o docs/api/openapi.json
```

Then set collection variables `host`, `email`, and `password` to match `fintrack.http`.

## Swagger UI

Interactive docs: [http://localhost:8080/api/v1/swagger-ui.html](http://localhost:8080/api/v1/swagger-ui.html)
