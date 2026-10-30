'use strict';

const http = require('node:http');
const crypto = require('node:crypto');

const args = process.argv.slice(2);
function arg(name, fallback) {
  const i = args.indexOf('--' + name);
  return i !== -1 && args[i + 1] ? args[i + 1] : fallback;
}

const PORT = Number(arg('port', process.env.PORT || 8080));
const ORIGIN = arg('origin', process.env.ORIGIN || '*');
const SECRET = 'учебный-ключ-не-для-продакшена';
const ACCESS_TTL = Number(arg('ttl', 900));
const REFRESH_TTL = 60 * 60 * 24 * 7;

// ─────────────────────────────── токены ───────────────────────────────

function sign(payload) {
  const body = Buffer.from(JSON.stringify({ ...payload, jti: crypto.randomUUID() })).toString('base64url');
  const mac = crypto.createHmac('sha256', SECRET).update(body).digest('base64url');
  return body + '.' + mac;
}

function verify(token) {
  if (typeof token !== 'string' || !token.includes('.')) return null;
  const [body, mac] = token.split('.');
  if (mac !== crypto.createHmac('sha256', SECRET).update(body).digest('base64url')) return null;
  let payload;
  try {
    payload = JSON.parse(Buffer.from(body, 'base64url').toString('utf8'));
  } catch {
    return null;
  }
  if (payload.exp && payload.exp * 1000 < Date.now()) return null;
  return payload;
}

const hash = (password) => crypto.createHash('sha256').update(password + SECRET).digest('hex');

function issueTokens(user) {
  const now = Math.floor(Date.now() / 1000);
  const accessToken = sign({ sub: user.id, role: user.role, type: 'access', exp: now + ACCESS_TTL });
  const refreshToken = sign({ sub: user.id, type: 'refresh', exp: now + REFRESH_TTL });
  db.refreshTokens.add(refreshToken);
  return { accessToken, refreshToken, expiresIn: ACCESS_TTL, user: expandUser(user) };
}

const expandUser = (u) => ({
  id: u.id,
  username: u.username,
  fullName: u.fullName,
  role: u.role,
  clientId: u.clientId,
});

const ROLE_LEVEL = { client: 1, manager: 2, admin: 3 };

// ─────────────────────────────── данные ───────────────────────────────

let db;

function push(collection, obj) {
  db.seq[collection] = (db.seq[collection] || 0) + 1;
  const id = db.seq[collection];
  db[collection].push({ id, ...obj, deletedAt: null });
  return id;
}

const NAMES = [
  'Иванов Алексей Петрович', 'Петров Сергей Николаевич', 'Сидоров Дмитрий Андреевич',
  'Козлов Андрей Викторович', 'Николаев Павел Олегович', 'Орлов Виктор Сергеевич',
  'Захаров Михаил Ильич', 'Белов Иван Константинович', 'Тарасов Олег Владимирович',
  'Ефимов Георгий Романович', 'Гусев Антон Евгеньевич', 'Борисов Матвей Денисович',
];

function phone(i) {
  const p = (n) => String(n).padStart(2, '0');
  return `+7 9${p(((10 + i * 3) % 90) + 10)} ${((i * 37) % 900) + 100} ${p(((i * 13) % 90) + 10)} ${p(((i * 29) % 90) + 10)}`;
}

function seed() {
  db = {
    seq: {}, services: [], branches: [], barbers: [], clients: [], appointments: [],
    users: [], refreshTokens: new Set(),
  };

  [
    ['Мужская стрижка', 1500, 60], ['Стрижка машинкой', 900, 30], ['Стрижка бороды', 1000, 30],
    ['Стрижка и борода', 2200, 90], ['Детская стрижка', 1000, 45],
    ['Бритьё опасной бритвой', 1200, 45], ['Камуфляж седины', 1300, 30],
  ].forEach(([name, price, duration]) => push('services', { name, price, duration }));

  [['Центральный', 'ул. Ленина, 10'], ['Северный', 'пр. Мира, 45'], ['Южный', 'ул. Садовая, 7']]
    .forEach(([name, address]) => push('branches', { name, address }));

  [
    ['Смирнов Артём Игоревич', 1994, 1], ['Кузнецов Денис Олегович', 1990, 2],
    ['Попов Максим Сергеевич', 1998, 3], ['Васильев Илья Андреевич', 1987, 1],
    ['Морозов Кирилл Павлович', 2000, 2], ['Волков Тимур Русланович', 1992, 3],
    ['Соколов Никита Евгеньевич', 1996, 1], ['Лебедев Роман Алексеевич', 1985, 2],
    ['Новиков Егор Дмитриевич', 2001, 3], ['Фёдоров Глеб Викторович', 1989, 1],
    ['Михайлов Арсений Ильич', 1997, 2],
  ].forEach(([fullName, birthYear, branchId]) => push('barbers', { fullName, birthYear, branchId }));

  NAMES.forEach((fullName, i) =>
    push('clients', {
      fullName,
      phone: phone(i),
      email: `client${i + 1}@mail.ru`,
      card: { number: String(100001 + i * 17), discount: (i % 4) * 5 },
    })
  );

  const U = (username, password, fullName, role, clientId) =>
    push('users', { username, passwordHash: hash(password), fullName, role, clientId });
  U('admin', 'admin123', 'Администратор', 'admin', null);
  U('manager', 'manager123', 'Менеджер салона', 'manager', null);
  U('client', 'client123', NAMES[0], 'client', 1);

  for (let i = 0; i < 30; i++) {
    const serviceIds = i % 3 === 0 ? [(i % 7) + 1, 3] : [(i % 7) + 1];
    const month = 10 + (i % 2);
    const day = 1 + ((i * 7) % 30);
    const hour = 10 + ((i * 3) % 10);
    const p = (n) => String(n).padStart(2, '0');
    push('appointments', {
      clientId: (i % 12) + 1,
      barberId: (i % 11) + 1,
      serviceIds,
      date: `2026-${p(month)}-${p(day)}T${p(hour)}:${i % 2 ? '30' : '00'}:00`,
      price: serviceIds.reduce((s, id) => s + db.services.find((x) => x.id === id).price, 0),
    });
  }
}

const byId = (collection, id) => db[collection].find((x) => x.id === id);

function expandAppointment(a) {
  const client = byId('clients', a.clientId);
  const barber = byId('barbers', a.barberId);
  return {
    id: a.id,
    client: client ? { id: client.id, fullName: client.fullName, phone: client.phone } : null,
    barber: barber ? { id: barber.id, fullName: barber.fullName } : null,
    services: a.serviceIds
      .map((id) => byId('services', id))
      .filter(Boolean)
      .map((s) => ({ id: s.id, name: s.name, price: s.price })),
    date: a.date,
    price: a.price,
    deletedAt: a.deletedAt,
  };
}

function expandBarber(b) {
  const branch = byId('branches', b.branchId);
  return {
    id: b.id,
    fullName: b.fullName,
    birthYear: b.birthYear,
    branch: branch ? { id: branch.id, name: branch.name } : null,
    deletedAt: b.deletedAt,
  };
}

const EXPANDERS = {
  appointments: expandAppointment,
  barbers: expandBarber,
  services: (x) => x,
  branches: (x) => x,
  clients: (x) => x,
};

const COLLECTIONS = Object.keys(EXPANDERS);

function searchableText(collection, x) {
  switch (collection) {
    case 'appointments': {
      const c = byId('clients', x.clientId);
      return c ? `${c.fullName} ${c.phone}` : '';
    }
    case 'barbers': return x.fullName;
    case 'services': return x.name;
    case 'branches': return `${x.name} ${x.address}`;
    case 'clients': return `${x.fullName} ${x.email} ${x.phone}`;
    default: return '';
  }
}

function applyFilters(collection, rows, q) {
  let result = rows;
  if (q.search) {
    const needle = String(q.search).toLowerCase();
    result = result.filter((x) => searchableText(collection, x).toLowerCase().includes(needle));
  }
  if (collection === 'appointments') {
    if (q.serviceId) result = result.filter((a) => a.serviceIds.includes(Number(q.serviceId)));
    if (q.barberId) result = result.filter((a) => a.barberId === Number(q.barberId));
    if (q.clientId) result = result.filter((a) => a.clientId === Number(q.clientId));
    if (q.dateFrom) result = result.filter((a) => a.date.slice(0, 10) >= q.dateFrom);
    if (q.dateTo) result = result.filter((a) => a.date.slice(0, 10) <= q.dateTo);
  }
  if (collection === 'barbers' && q.branchId) {
    result = result.filter((b) => b.branchId === Number(q.branchId));
  }
  return result;
}

function sortValue(collection, x, field) {
  if (collection === 'appointments' && field === 'clientName') {
    const c = byId('clients', x.clientId);
    return c ? c.fullName : null;
  }
  if (collection === 'clients' && field === 'discount') return x.card.discount;
  return x[field];
}

function applySort(collection, rows, sort) {
  if (!sort) return rows;
  const [field, dirRaw] = String(sort).split(',');
  const dir = (dirRaw || 'asc').toLowerCase() === 'desc' ? -1 : 1;
  return [...rows].sort((a, b) => {
    const av = sortValue(collection, a, field);
    const bv = sortValue(collection, b, field);
    if (av == null && bv == null) return 0;
    if (av == null) return 1;
    if (bv == null) return -1;
    if (typeof av === 'number' && typeof bv === 'number') return (av - bv) * dir;
    return String(av).localeCompare(String(bv), 'ru') * dir;
  });
}

function paginate(rows, q) {
  const page = Math.max(1, Number(q.page) || 1);
  const size = Math.min(100, Math.max(1, Number(q.size) || 10));
  const total = rows.length;
  return {
    items: rows.slice((page - 1) * size, page * size),
    page,
    size,
    total,
    totalPages: Math.max(1, Math.ceil(total / size)),
  };
}

const str = (v) => (typeof v === 'string' ? v.trim() : '');
const alive = (collection, id) => db[collection].find((x) => x.id === Number(id) && !x.deletedAt);
const normDate = (v) => str(v).slice(0, 16) + ':00';

function validate(collection, body, id = null) {
  const e = {};
  const intIn = (v, min, max) => Number.isInteger(Number(v)) && Number(v) >= min && Number(v) <= max;

  if (collection === 'appointments') {
    if (!alive('clients', body.clientId)) e.clientId = 'Клиент не найден';
    if (!alive('barbers', body.barberId)) e.barberId = 'Барбер не найден';
    const ids = Array.isArray(body.serviceIds) ? body.serviceIds : [];
    if (!ids.length) e.serviceIds = 'Выберите хотя бы одну услугу';
    else if (ids.some((s) => !byId('services', Number(s)))) e.serviceIds = 'Услуга не найдена';
    if (!/^\d{4}-\d{2}-\d{2}T\d{2}:\d{2}/.test(str(body.date))) e.date = 'Некорректная дата';
    if (!intIn(body.price, 1, 100000)) e.price = 'Стоимость от 1 до 100000';
  }

  if (collection === 'barbers') {
    if (str(body.fullName).length < 5) e.fullName = 'ФИО не короче 5 символов';
    if (!intIn(body.birthYear, 1950, new Date().getFullYear() - 18)) e.birthYear = 'Некорректный год рождения';
    if (!alive('branches', body.branchId)) e.branchId = 'Филиал не найден';
  }

  if (collection === 'services') {
    if (!str(body.name)) e.name = 'Укажите название';
    if (!intIn(body.price, 1, 100000)) e.price = 'Цена от 1 до 100000';
    if (!intIn(body.duration, 5, 300)) e.duration = 'Длительность от 5 до 300 минут';
  }

  if (collection === 'branches') {
    if (!str(body.name)) e.name = 'Укажите название';
    if (!str(body.address)) e.address = 'Укажите адрес';
  }

  if (collection === 'clients') {
    if (str(body.fullName).length < 5) e.fullName = 'ФИО не короче 5 символов';
    const email = str(body.email);
    if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email)) e.email = 'Некорректный адрес почты';
    else if (db.clients.find((c) => c.email.toLowerCase() === email.toLowerCase() && c.id !== id && !c.deletedAt)) {
      e.email = 'Клиент с такой почтой уже есть';
    }
    const card = body.card || {};
    const number = str(card.number);
    if (!/^\d{6}$/.test(number)) e.cardNumber = 'Номер карты — 6 цифр';
    else if (db.clients.find((c) => c.card.number === number && c.id !== id && !c.deletedAt)) {
      e.cardNumber = 'Карта с таким номером уже выдана';
    }
    if (!intIn(card.discount, 0, 30)) e.cardDiscount = 'Скидка от 0 до 30%';
  }

  return e;
}

function normalize(collection, body) {
  const num = (v) => Number(v);
  switch (collection) {
    case 'appointments':
      return {
        clientId: num(body.clientId),
        barberId: num(body.barberId),
        serviceIds: body.serviceIds.map(Number),
        date: normDate(body.date),
        price: num(body.price),
      };
    case 'barbers':
      return { fullName: str(body.fullName), birthYear: num(body.birthYear), branchId: num(body.branchId) };
    case 'services':
      return { name: str(body.name), price: num(body.price), duration: num(body.duration) };
    case 'branches':
      return { name: str(body.name), address: str(body.address) };
    case 'clients':
      return {
        fullName: str(body.fullName),
        phone: str(body.phone),
        email: str(body.email),
        card: { number: str(body.card.number), discount: num(body.card.discount) },
      };
    default:
      return { ...body };
  }
}

function slotConflict(body, id = null) {
  const date = normDate(body.date);
  return db.appointments.some(
    (a) => a.id !== id && !a.deletedAt && a.barberId === Number(body.barberId) && a.date === date
  );
}

function deleteBlocker(collection, ids) {
  const count = (rows) => rows.length;
  if (collection === 'branches') {
    const n = count(db.barbers.filter((b) => ids.includes(b.branchId)));
    if (n) return `Нельзя удалить филиал: к нему привязано барберов — ${n}`;
  }
  if (collection === 'barbers') {
    const n = count(db.appointments.filter((a) => ids.includes(a.barberId)));
    if (n) return `Нельзя удалить барбера: у него есть записи — ${n}`;
  }
  if (collection === 'services') {
    const n = count(db.appointments.filter((a) => a.serviceIds.some((s) => ids.includes(s))));
    if (n) return `Нельзя удалить услугу: она указана в записях — ${n}`;
  }
  if (collection === 'clients') {
    const n = count(db.appointments.filter((a) => ids.includes(a.clientId)));
    if (n) return `Нельзя удалить клиента: у него есть записи — ${n}`;
  }
  return null;
}

function cors(res) {
  res.setHeader('Access-Control-Allow-Origin', ORIGIN);
  res.setHeader('Access-Control-Allow-Methods', 'GET, POST, PUT, PATCH, DELETE, OPTIONS');
  res.setHeader('Access-Control-Allow-Headers', 'Content-Type, Authorization');
  res.setHeader('Access-Control-Max-Age', '86400');
  res.setHeader('Vary', 'Origin');
}

function send(res, status, payload) {
  cors(res);
  if (payload === undefined || status === 204) {
    res.writeHead(204);
    res.end();
    return;
  }
  const body = JSON.stringify(payload, null, 2);
  res.writeHead(status, {
    'Content-Type': 'application/json; charset=utf-8',
    'Content-Length': Buffer.byteLength(body),
  });
  res.end(body);
}

const fail = (res, status, message) => send(res, status, { message });
const invalid = (res, errors) => send(res, 422, { message: 'Ошибка валидации', errors });

async function readBody(req) {
  const chunks = [];
  for await (const chunk of req) chunks.push(chunk);
  if (!chunks.length) return {};
  try {
    return JSON.parse(Buffer.concat(chunks).toString('utf8'));
  } catch {
    return null;
  }
}

function currentUser(req) {
  const header = req.headers['authorization'] || '';
  if (!header.startsWith('Bearer ')) return null;
  const payload = verify(header.slice(7));
  if (!payload || payload.type !== 'access') return null;
  return db.users.find((u) => u.id === payload.sub && !u.deletedAt) || null;
}

function allowed(res, user, minRole) {
  if (ROLE_LEVEL[user.role] >= ROLE_LEVEL[minRole]) return true;
  fail(res, 403, 'Недостаточно прав для этого действия');
  return false;
}

function validatePassword(password) {
  if (password.length < 8) return 'Пароль не короче восьми символов';
  if (!/\d/.test(password)) return 'Пароль должен содержать цифру';
  if (!/[^\w\s]/.test(password)) return 'Пароль должен содержать специальный символ';
  return null;
}

async function handleAuth(req, res, path) {
  const body = (await readBody(req)) || {};

  if (path === '/api/auth/register') {
    const e = {};
    const username = str(body.username);
    if (username.length < 3) e.username = 'Логин не короче трёх символов';
    else if (db.users.find((u) => u.username === username)) e.username = 'Такой логин уже занят';
    const passwordError = validatePassword(String(body.password || ''));
    if (passwordError) e.password = passwordError;
    if (str(body.fullName).length < 5) e.fullName = 'ФИО не короче 5 символов';
    const email = str(body.email);
    if (!/^[\w.+-]+@[\w-]+\.[\w.-]+$/.test(email)) e.email = 'Некорректный адрес почты';
    else if (db.clients.find((c) => c.email.toLowerCase() === email.toLowerCase() && !c.deletedAt)) {
      e.email = 'Клиент с такой почтой уже есть';
    }
    if (!str(body.phone)) e.phone = 'Укажите телефон';
    if (Object.keys(e).length) return invalid(res, e);

    const clientId = push('clients', {
      fullName: str(body.fullName),
      phone: str(body.phone),
      email,
      card: { number: String(200000 + (db.seq.clients || 0) + 1), discount: 0 },
    });
    const userId = push('users', {
      username,
      passwordHash: hash(String(body.password)),
      fullName: str(body.fullName),
      role: 'client',
      clientId,
    });
    return send(res, 201, expandUser(byId('users', userId)));
  }

  if (path === '/api/auth/login') {
    const found = db.users.find((u) => u.username === str(body.username) && !u.deletedAt);
    if (!found || found.passwordHash !== hash(String(body.password || ''))) {
      return fail(res, 401, 'Неверный логин или пароль');
    }
    return send(res, 200, issueTokens(found));
  }

  if (path === '/api/auth/refresh') {
    const token = body.refreshToken;
    const payload = verify(token);
    if (!payload || payload.type !== 'refresh' || !db.refreshTokens.has(token)) {
      return fail(res, 401, 'Токен обновления недействителен');
    }
    const found = byId('users', payload.sub);
    if (!found) return fail(res, 401, 'Пользователь не найден');
    db.refreshTokens.delete(token);
    return send(res, 200, issueTokens(found));
  }

  if (path === '/api/auth/logout') {
    if (body.refreshToken) db.refreshTokens.delete(body.refreshToken);
    return send(res, 204);
  }

  return fail(res, 404, 'Адрес не обслуживается');
}

async function handle(req, res, url) {
  const q = Object.fromEntries(url.searchParams.entries());
  const path = url.pathname.replace(/\/+$/, '') || '/';
  const method = req.method.toUpperCase();

  if (q.__fail) return fail(res, Number(q.__fail), 'Ошибка вызвана намеренно параметром __fail');

  if (path === '/api/__reset' && method === 'POST') {
    seed();
    return send(res, 200, { message: 'Данные восстановлены в исходное состояние' });
  }
  if (path === '/api/__health' && method === 'GET') {
    return send(res, 200, { status: 'ok', time: new Date().toISOString() });
  }

  if (path.startsWith('/api/auth/') && method === 'POST' && path !== '/api/auth/me') {
    return handleAuth(req, res, path);
  }

  const user = currentUser(req);
  if (!user) return fail(res, 401, 'Требуется вход в систему');

  if (path === '/api/auth/me' && method === 'GET') return send(res, 200, expandUser(user));

  if (path === '/api/users' && method === 'GET') {
    if (!allowed(res, user, 'admin')) return;
    return send(res, 200, { items: db.users.map(expandUser) });
  }

  let um = path.match(/^\/api\/users\/(\d+)\/role$/);
  if (um && method === 'PUT') {
    if (!allowed(res, user, 'admin')) return;
    const target = byId('users', Number(um[1]));
    if (!target) return fail(res, 404, 'Пользователь не найден');
    const body = (await readBody(req)) || {};
    if (!ROLE_LEVEL[body.role]) return invalid(res, { role: 'Неизвестная роль' });
    if (target.id === user.id) return fail(res, 409, 'Нельзя изменить собственную роль');
    target.role = body.role;
    return send(res, 200, expandUser(target));
  }

  if (path === '/api/stats' && method === 'GET') {
    if (!allowed(res, user, 'admin')) return;
    const active = db.appointments.filter((a) => !a.deletedAt);
    const users = {};
    for (const u of db.users) users[u.role] = (users[u.role] || 0) + 1;
    return send(res, 200, {
      appointments: active.length,
      revenue: active.reduce((s, a) => s + a.price, 0),
      clients: db.clients.filter((c) => !c.deletedAt).length,
      barbers: db.barbers.filter((b) => !b.deletedAt).length,
      users,
      topBarbers: db.barbers
        .map((b) => ({ fullName: b.fullName, count: active.filter((a) => a.barberId === b.id).length }))
        .sort((a, b) => b.count - a.count)
        .slice(0, 5),
    });
  }

  um = path.match(/^\/api\/appointments\/(\d+)\/cancel$/);
  if (um && method === 'POST') {
    const row = db.appointments.find((a) => a.id === Number(um[1]) && !a.deletedAt);
    if (!row) return fail(res, 404, 'Запись не найдена');
    if (user.role === 'client' && row.clientId !== user.clientId) {
      return fail(res, 403, 'Можно отменить только свою запись');
    }
    row.deletedAt = new Date().toISOString();
    return send(res, 204);
  }

  const bulk = path.match(/^\/api\/([a-z]+)\/bulk-delete$/);
  if (bulk && method === 'POST') {
    const collection = bulk[1];
    if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
    if (!allowed(res, user, 'manager')) return;
    const body = await readBody(req);
    const ids = Array.isArray(body && body.ids) ? body.ids.map(Number) : [];
    if (!ids.length) return invalid(res, { ids: 'Передайте непустой список идентификаторов' });
    const blocked = deleteBlocker(collection, ids);
    if (blocked) return fail(res, 409, blocked);
    let deleted = 0;
    for (const row of db[collection]) {
      if (ids.includes(row.id) && !row.deletedAt) {
        row.deletedAt = new Date().toISOString();
        deleted += 1;
      }
    }
    return send(res, 200, { deleted });
  }

  const m = path.match(/^\/api\/([a-z]+)(?:\/(\d+))?(?:\/(restore))?$/);
  if (!m) return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);

  const collection = m[1];
  const id = m[2] ? Number(m[2]) : null;
  const action = m[3] || null;
  if (!COLLECTIONS.includes(collection)) return fail(res, 404, 'Ресурс не найден');
  const expand = EXPANDERS[collection];

  const isClient = user.role === 'client';
  if (collection === 'clients' && isClient && !(method === 'GET' && id === user.clientId)) {
    return fail(res, 403, 'Недостаточно прав для этого действия');
  }

  if (action === 'restore' && method === 'POST') {
    if (!allowed(res, user, 'admin')) return;
    const row = byId(collection, id);
    if (!row) return fail(res, 404, 'Объект не найден');
    row.deletedAt = null;
    return send(res, 200, expand(row));
  }

  if (id === null && method === 'GET') {
    let rows = db[collection];
    if (q.includeDeleted !== 'true') rows = rows.filter((x) => !x.deletedAt);
    if (collection === 'appointments' && isClient) rows = rows.filter((a) => a.clientId === user.clientId);
    rows = applyFilters(collection, rows, q);
    rows = applySort(collection, rows, q.sort);
    const page = paginate(rows, q);
    return send(res, 200, { ...page, items: page.items.map(expand) });
  }

  if (id !== null && method === 'GET') {
    const row = db[collection].find((x) => x.id === id && (q.includeDeleted === 'true' || !x.deletedAt));
    if (!row) return fail(res, 404, 'Объект не найден');
    if (collection === 'appointments' && isClient && row.clientId !== user.clientId) {
      return fail(res, 403, 'Это чужая запись');
    }
    return send(res, 200, expand(row));
  }

  if (method !== 'GET' && !allowed(res, user, q.hard === 'true' ? 'admin' : 'manager')) return;

  if (id === null && method === 'POST') {
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const errors = validate(collection, body);
    if (Object.keys(errors).length) return invalid(res, errors);
    if (collection === 'appointments' && slotConflict(body)) {
      return fail(res, 409, 'Барбер уже занят в это время');
    }
    const newId = push(collection, normalize(collection, body));
    return send(res, 201, expand(byId(collection, newId)));
  }

  if (id !== null && method === 'PUT') {
    const row = byId(collection, id);
    if (!row) return fail(res, 404, 'Объект не найден');
    const body = await readBody(req);
    if (!body) return fail(res, 400, 'Тело запроса не является корректным JSON');
    const errors = validate(collection, body, id);
    if (Object.keys(errors).length) return invalid(res, errors);
    if (collection === 'appointments' && slotConflict(body, id)) {
      return fail(res, 409, 'Барбер уже занят в это время');
    }
    Object.assign(row, normalize(collection, body));
    return send(res, 200, expand(row));
  }

  if (id !== null && method === 'DELETE') {
    const index = db[collection].findIndex((x) => x.id === id);
    if (index === -1) return fail(res, 404, 'Объект не найден');
    const blocked = deleteBlocker(collection, [id]);
    if (blocked) return fail(res, 409, blocked);
    if (q.hard === 'true') db[collection].splice(index, 1);
    else db[collection][index].deletedAt = new Date().toISOString();
    return send(res, 204);
  }

  return fail(res, 404, `Адрес ${method} ${path} не обслуживается`);
}

// ───────────────────────── хранение в Supabase ─────────────────────────
// Данные лежат в связанных таблицах (схема — supabase-schema.sql).
// При запуске сервер читает таблицы, после каждого изменения
// отправляет в Supabase только изменившиеся строки.

const SUPABASE_URL = process.env.SUPABASE_URL;
const SUPABASE_KEY = process.env.SUPABASE_KEY;
const useSupabase = Boolean(SUPABASE_URL && SUPABASE_KEY);

async function rest(method, table, query, body) {
  const headers = { apikey: SUPABASE_KEY, 'Content-Type': 'application/json' };
  if (SUPABASE_KEY.split('.').length === 3) headers.Authorization = `Bearer ${SUPABASE_KEY}`;
  if (method === 'POST') headers.Prefer = 'resolution=merge-duplicates,return=minimal';
  const response = await fetch(`${SUPABASE_URL}/rest/v1/${table}${query}`, {
    method,
    headers,
    body: body === undefined ? undefined : JSON.stringify(body),
  });
  if (!response.ok) {
    throw new Error(`Supabase ${method} ${table}: ${response.status} ${await response.text()}`);
  }
  return method === 'GET' ? response.json() : null;
}

// Порядок важен: родительские таблицы раньше дочерних
const TABLES = [
  {
    name: 'branches',
    key: ['id'],
    rows: () => db.branches.map((b) => ({ id: b.id, name: b.name, address: b.address, deleted_at: b.deletedAt })),
  },
  {
    name: 'services',
    key: ['id'],
    rows: () =>
      db.services.map((s) => ({
        id: s.id, name: s.name, price: s.price, duration: s.duration, deleted_at: s.deletedAt,
      })),
  },
  {
    name: 'clients',
    key: ['id'],
    rows: () =>
      db.clients.map((c) => ({
        id: c.id, full_name: c.fullName, phone: c.phone, email: c.email, deleted_at: c.deletedAt,
      })),
  },
  {
    name: 'client_cards',
    key: ['client_id'],
    rows: () => db.clients.map((c) => ({ client_id: c.id, number: c.card.number, discount: c.card.discount })),
  },
  {
    name: 'barbers',
    key: ['id'],
    rows: () =>
      db.barbers.map((b) => ({
        id: b.id, full_name: b.fullName, birth_year: b.birthYear, branch_id: b.branchId, deleted_at: b.deletedAt,
      })),
  },
  {
    name: 'users',
    key: ['id'],
    rows: () =>
      db.users.map((u) => ({
        id: u.id, username: u.username, password_hash: u.passwordHash, full_name: u.fullName,
        role: u.role, client_id: u.clientId, deleted_at: u.deletedAt,
      })),
  },
  {
    name: 'appointments',
    key: ['id'],
    rows: () =>
      db.appointments.map((a) => ({
        id: a.id, client_id: a.clientId, barber_id: a.barberId, date: a.date, price: a.price,
        deleted_at: a.deletedAt,
      })),
  },
  {
    name: 'appointment_services',
    key: ['appointment_id', 'service_id'],
    rows: () =>
      db.appointments.flatMap((a) => a.serviceIds.map((s) => ({ appointment_id: a.id, service_id: s }))),
  },
  {
    name: 'refresh_tokens',
    key: ['token'],
    rows: () => [...db.refreshTokens].map((token) => ({ token })),
  },
];

const saved = new Map();
const keyOf = (table, row) => table.key.map((k) => row[k]).join('|');
const snapshot = (table) => new Map(table.rows().map((r) => [keyOf(table, r), JSON.stringify(r)]));

async function saveChanges() {
  const current = new Map(TABLES.map((t) => [t.name, snapshot(t)]));

  // Удаления — от дочерних таблиц к родительским
  for (const table of [...TABLES].reverse()) {
    const now = current.get(table.name);
    for (const [key, json] of saved.get(table.name) || []) {
      if (now.has(key)) continue;
      const row = JSON.parse(json);
      const filter = table.key.map((k) => `${k}=eq.${encodeURIComponent(row[k])}`).join('&');
      await rest('DELETE', table.name, `?${filter}`);
    }
  }

  // Новые и изменённые строки — от родительских к дочерним
  for (const table of TABLES) {
    const before = saved.get(table.name) || new Map();
    const changed = [...current.get(table.name)]
      .filter(([key, json]) => before.get(key) !== json)
      .map(([, json]) => JSON.parse(json));
    if (changed.length) await rest('POST', table.name, `?on_conflict=${table.key.join(',')}`, changed);
  }

  for (const [name, snap] of current) saved.set(name, snap);
}

async function loadState() {
  const data = {};
  for (const table of TABLES) data[table.name] = await rest('GET', table.name, '?select=*');
  if (!data.users.length) return false;

  const byId = (a, b) => a.id - b.id;
  const cards = new Map(data.client_cards.map((c) => [c.client_id, c]));
  const servicesOf = new Map();
  for (const r of data.appointment_services) {
    servicesOf.set(r.appointment_id, [...(servicesOf.get(r.appointment_id) || []), r.service_id]);
  }

  db = {
    seq: {},
    branches: data.branches
      .map((b) => ({ id: b.id, name: b.name, address: b.address, deletedAt: b.deleted_at }))
      .sort(byId),
    services: data.services
      .map((s) => ({ id: s.id, name: s.name, price: s.price, duration: s.duration, deletedAt: s.deleted_at }))
      .sort(byId),
    clients: data.clients
      .map((c) => ({
        id: c.id, fullName: c.full_name, phone: c.phone, email: c.email,
        card: { number: cards.get(c.id)?.number ?? '', discount: cards.get(c.id)?.discount ?? 0 },
        deletedAt: c.deleted_at,
      }))
      .sort(byId),
    barbers: data.barbers
      .map((b) => ({
        id: b.id, fullName: b.full_name, birthYear: b.birth_year, branchId: b.branch_id, deletedAt: b.deleted_at,
      }))
      .sort(byId),
    users: data.users
      .map((u) => ({
        id: u.id, username: u.username, passwordHash: u.password_hash, fullName: u.full_name,
        role: u.role, clientId: u.client_id, deletedAt: u.deleted_at,
      }))
      .sort(byId),
    appointments: data.appointments
      .map((a) => ({
        id: a.id, clientId: a.client_id, barberId: a.barber_id,
        serviceIds: (servicesOf.get(a.id) || []).sort((x, y) => x - y),
        date: a.date, price: a.price, deletedAt: a.deleted_at,
      }))
      .sort(byId),
    refreshTokens: new Set(data.refresh_tokens.map((r) => r.token)),
  };
  for (const name of ['branches', 'services', 'clients', 'barbers', 'users', 'appointments']) {
    db.seq[name] = db[name].reduce((max, x) => Math.max(max, x.id), 0);
  }
  for (const table of TABLES) saved.set(table.name, snapshot(table));
  return true;
}

let saving = Promise.resolve();
const persist = () => (saving = saving.then(saveChanges).catch((e) => console.error(e.message)));

const server = http.createServer(async (req, res) => {
  const url = new URL(req.url, `http://${req.headers.host || 'localhost'}`);

  if (req.method === 'OPTIONS') {
    cors(res);
    res.writeHead(204);
    return res.end();
  }

  const delay = Number(url.searchParams.get('__delay') || 0);
  if (delay > 0) await new Promise((r) => setTimeout(r, Math.min(delay, 10000)));

  const started = Date.now();
  try {
    await handle(req, res, url);
  } catch (err) {
    console.error(err);
    if (!res.headersSent) fail(res, 500, 'Внутренняя ошибка сервера: ' + err.message);
  }
  if (useSupabase && req.method !== 'GET' && res.statusCode < 400) persist();
  console.log(`${req.method.padEnd(6)} ${url.pathname}${url.search}  → ${res.statusCode}  ${Date.now() - started} мс`);
});

async function start() {
  if (!useSupabase) {
    seed();
  } else if (!(await loadState())) {
    seed();
    await saveChanges();
  }
  server.listen(PORT, () => {
    console.log('');
    console.log('  Учебное API «Барбершоп»');
    console.log(`  Адрес:                http://localhost:${PORT}/api`);
    console.log(`  Разрешённый источник: ${ORIGIN}`);
    console.log(`  Срок жизни токена:    ${ACCESS_TTL} с`);
    console.log('  Учётные записи:       admin/admin123  manager/manager123  client/client123');
    console.log('  Сброс данных:         POST /api/__reset');
    console.log('  Задержка ответа:      ?__delay=1500');
    console.log('  Ошибка по требованию: ?__fail=500');
    console.log(`  Хранение данных:      ${useSupabase ? 'Supabase (связанные таблицы)' : 'в памяти'}`);
    console.log('');
  });
}

start().catch((err) => {
  console.error('Не удалось запустить сервер:', err.message);
  process.exit(1);
});
