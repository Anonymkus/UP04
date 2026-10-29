# Контракт учебного API «Барбершоп»

Базовый адрес: `http://localhost:8080/api`. Формат — JSON. Авторизация пока не требуется.

Запуск: `node server/mock-server.js --port 8080 --origin http://localhost:5555`
Клиент: `flutter run -d chrome --web-port=5555 --dart-define=API_BASE_URL=http://localhost:8080/api`

## Общие соглашения

Оболочка списка: `{ "items": [...], "page": 1, "size": 10, "total": 30, "totalPages": 3 }`

| Код | Смысл | Тело |
|---|---|---|
| 404 | объект не найден | `{ "message": "..." }` |
| 409 | конфликт: барбер занят, удаление запрещено связями | `{ "message": "..." }` |
| 422 | ошибка валидации | `{ "message": "...", "errors": { "поле": "текст" } }` |
| 500 | ошибка сервера | `{ "message": "..." }` |

Учебные параметры: `?__delay=1500` — задержка, `?__fail=500` — принудительная ошибка.

## Ресурсы

`appointments`, `barbers`, `services`, `branches`, `clients` — одинаковый набор операций:

| Запрос | Действие |
|---|---|
| `GET /api/{res}?search=&sort=поле,asc&page=&size=&includeDeleted=` | список |
| `GET /api/{res}/{id}` | одна запись |
| `POST /api/{res}` | создание, ответ 201 |
| `PUT /api/{res}/{id}` | изменение |
| `DELETE /api/{res}/{id}` | логическое удаление, 204 |
| `DELETE /api/{res}/{id}?hard=true` | физическое удаление, 204 |
| `POST /api/{res}/bulk-delete` `{ "ids": [1,2] }` | множественное удаление, `{ "deleted": 2 }` |
| `POST /api/{res}/{id}/restore` | восстановление |

Фильтры записей: `serviceId`, `barberId`, `clientId`, `dateFrom`, `dateTo` (`ГГГГ-ММ-ДД`). Барберов: `branchId`.

Удаление филиала с барберами, а также барбера, услуги или клиента, на которых есть записи, — `409`.

## Модели

Запись — на чтение приходят развёрнутые объекты, на запись отправляются идентификаторы:

```json
{
  "id": 1,
  "client": { "id": 1, "fullName": "Иванов Алексей Петрович", "phone": "+7 920 100 10 10" },
  "barber": { "id": 1, "fullName": "Смирнов Артём Игоревич" },
  "services": [ { "id": 1, "name": "Мужская стрижка", "price": 1500 } ],
  "date": "2026-10-01T10:00:00",
  "price": 2500,
  "deletedAt": null
}
```

Тело `POST`/`PUT`: `{ "clientId": 1, "barberId": 1, "serviceIds": [1, 3], "date": "2026-10-01T10:00:00", "price": 2500 }`.
Если барбер уже занят в это время — `409`.

Барбер: `{ "id", "fullName", "birthYear", "branch": { "id", "name" } }`, на запись — `branchId`.
Услуга: `{ "id", "name", "price", "duration" }`.
Филиал: `{ "id", "name", "address" }`.
Клиент: `{ "id", "fullName", "phone", "email", "card": { "number", "discount" } }` — связь с картой один к одному.
Почта и номер карты уникальны, ошибки приходят в `422` с ключами `email`, `cardNumber`, `cardDiscount`.
