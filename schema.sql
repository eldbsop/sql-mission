## 카페 DB의 빈 표 4개를 만드는 파일.

PRAGMA foreign_keys = ON;

DROP TABLE IF EXISTS order_item;
DROP TABLE IF EXISTS orders;
DROP TABLE IF EXISTS menu;
DROP TABLE IF EXISTS customer;

## 고객 표
CREATE TABLE customer (
    customer_id INTEGER PRIMARY KEY AUTOINCREMENT,
    name        TEXT NOT NULL,
    phone       TEXT NOT NULL UNIQUE,
    joined_at   TEXT NOT NULL
);

## 메뉴 표
CREATE TABLE menu (
    menu_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    name     TEXT NOT NULL UNIQUE,
    category TEXT NOT NULL,                
    price    INTEGER NOT NULL
);

## 주문 표
CREATE TABLE orders (
    order_id    INTEGER PRIMARY KEY AUTOINCREMENT,
    customer_id INTEGER NOT NULL,
    ordered_at  TEXT NOT NULL,
    status      TEXT NOT NULL DEFAULT 'PREPARING'
                CHECK (status IN ('PREPARING', 'COMPLETED', 'CANCELED')),
    FOREIGN KEY (customer_id) REFERENCES customer(customer_id)
);

## 주문 상세 표
CREATE TABLE order_item (
    item_id  INTEGER PRIMARY KEY AUTOINCREMENT,
    order_id INTEGER NOT NULL,
    menu_id  INTEGER NOT NULL,
    quantity INTEGER NOT NULL CHECK (quantity > 0),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (menu_id)  REFERENCES menu(menu_id)
);