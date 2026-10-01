# 카페 주문 데이터베이스 (SQL 실습)

## 1. 프로젝트 소개

카페의 **고객, 메뉴, 주문, 주문 상세**를 SQLite 데이터베이스로 설계하고,
데이터를 넣은 뒤 SQL 쿼리로 필요한 정보를 뽑아본 실습입니다.
(백엔드 프레임워크는 사용하지 않았습니다.)

- DB: SQLite
- 도구: macOS 터미널의 `sqlite3`, VS Code

## 2. 파일 구성

| 파일 | 설명 |
|---|---|
| `schema.sql` | 테이블 4개 생성 (PK, FK, 제약조건 포함) |
| `data.sql` | 샘플 데이터 입력 (테이블마다 10행 이상) |
| `queries.sql` | 핵심 쿼리 16개 |
| `results/query_results.txt` | 쿼리 실행 결과 |
| `results/fk_error.txt` | FK가 잘못된 값을 막는 것을 확인한 에러 기록 |

## 3. 실행 방법

터미널에서 `sql-mission` 폴더로 이동한 뒤 순서대로 실행합니다.

```bash
sqlite3 cafe.db < schema.sql                            # 1) 테이블 만들기
sqlite3 cafe.db < data.sql                              # 2) 데이터 넣기
sqlite3 cafe.db < queries.sql > results/query_results.txt  # 3) 쿼리 실행 후 결과 저장
```

## 4. 데이터 모델

### 테이블

| 테이블 | 설명 | 주요 칸 |
|---|---|---|
| `customer` | 고객 | customer_id(PK), name, phone(UNIQUE), joined_at |
| `menu` | 메뉴 | menu_id(PK), name(UNIQUE), category, price |
| `orders` | 주문 (결제 1번 = 1줄) | order_id(PK), customer_id(FK), ordered_at, status |
| `order_item` | 주문 상세 (주문 안의 메뉴 한 줄) | item_id(PK), order_id(FK), menu_id(FK), quantity |

> 테이블 이름을 `order`가 아닌 `orders`로 한 이유: `order`는 SQL 예약어(`ORDER BY`)라서 오류가 나기 때문입니다.

### 관계 (1:N)

- `customer` 1 : N `orders` → 고객 1명이 주문을 여러 번 할 수 있다.
- `orders` 1 : N `order_item` → 주문 1건에 메뉴가 여러 줄 들어갈 수 있다.
- `menu` 1 : N `order_item` → 메뉴 1개가 여러 주문에 들어갈 수 있다.

### 제약조건

- `NOT NULL`: 이름, 가격, 주문 시각 등 꼭 필요한 칸
- `UNIQUE`: 고객 전화번호, 메뉴 이름
- `CHECK`: 주문 상태는 `PREPARING`, `COMPLETED`, `CANCELED`만 가능 / 수량은 1 이상
- `FOREIGN KEY`: 없는 고객, 없는 주문, 없는 메뉴는 참조할 수 없다.
  (SQLite는 기본적으로 FK 검사가 꺼져 있어서 `PRAGMA foreign_keys = ON;`을 사용했습니다.)

## 5. 쿼리 목록 (16개)

| 번호 | 종류 | 내용 |
|---|---|---|
| Q1 | 기본 조회 | 가장 비싼 메뉴 TOP 5 |
| Q2 | 기본 조회 | 5,500원 이상 메뉴 |
| Q3 | 기본 조회 | 이름에 "라떼"가 들어간 메뉴 검색 |
| Q4 | 기본 조회 | 준비 중인 주문을 최근 순으로 조회 |
| Q5 | INNER JOIN | 주문과 고객 이름 함께 보기 |
| Q6 | INNER JOIN (4개 표) | 주문 상세 내역 (누가, 무엇을, 몇 개, 얼마) |
| Q7 | LEFT JOIN | 주문이 한 번도 없는 고객 |
| Q8 | LEFT JOIN | 한 번도 주문되지 않은 메뉴 |
| Q9 | 집계 (COUNT) | 고객별 주문 횟수 |
| Q10 | 집계 (COUNT, AVG) | 분류별 메뉴 개수와 평균 가격 |
| Q11 | 집계 (SUM) | 메뉴별 판매 수량과 매출 TOP 3 (취소 주문 제외) |
| Q12 | 서브쿼리 | 주문이 없는 고객 (NOT IN) |
| Q13 | 서브쿼리 | 평균 가격보다 비싼 메뉴 |
| Q14 | 인덱스 | `orders(customer_id)`에 인덱스 생성 |
| Q15 | UPDATE | 9월 30일 이전 "준비 중" 주문을 "완료"로 변경 |
| Q16 | DELETE | 취소된 6번 주문 삭제 (자식 → 부모 순서) |

**인덱스 적용 이유:** 고객별 주문 조회와 JOIN을 자주 하므로, `customer_id`에 인덱스를 만들어 빠르게 찾을 수 있게 했습니다.

## 6. FK 동작 확인

존재하지 않는 고객(999번)으로 주문을 넣어 보았습니다.

```sql
INSERT INTO orders (customer_id, ordered_at) VALUES (999, '2026-10-01 10:00');
```

결과: `FOREIGN KEY constraint failed` 에러가 발생하며 입력이 거부되었습니다. (`results/fk_error.txt` 참고)

- **원인:** `customer` 테이블에 999번 고객이 없기 때문입니다.
- **해결:** 존재하는 고객 번호를 쓰거나, 새 고객이라면 `customer`에 먼저 추가한 뒤 주문을 입력합니다. (부모 먼저, 자식 나중)

## 7. 이 과제를 통해 이해한 것

**데이터베이스가 엑셀과 다른 점**
엑셀은 한 표에 모든 것을 적다 보니 같은 내용이 반복되기 쉽습니다.
데이터베이스는 표를 주제별로 나누고 번호(PK/FK)로 연결합니다. 그래서 중복이 줄고, 없는 값을 참조하는 실수를 규칙으로 막아줍니다.

**PK와 FK, 1:N 관계**
PK는 각 줄을 구분하는 고유 번호이고, FK는 다른 표의 PK를 가져다 적은 칸입니다.
예를 들어 `orders.customer_id`는 `customer`의 PK를 가리켜서, 고객 1명과 여러 주문을 연결합니다.

**SELECT / INSERT / UPDATE / DELETE**

| 명령 | 언제 쓰나 |
|---|---|
| SELECT | 데이터를 조회할 때 |
| INSERT | 새 데이터를 추가할 때 |
| UPDATE | 기존 데이터를 수정할 때 (WHERE 필수) |
| DELETE | 데이터를 삭제할 때 (WHERE 필수) |

**JOIN과 GROUP BY**
JOIN은 번호가 같은 줄끼리 여러 표를 이어붙여 한 번에 보여줍니다.
GROUP BY는 같은 값끼리 묶어서 COUNT, SUM, AVG 같은 계산을 합니다.

**인덱스**
책 뒤의 "찾아보기"처럼 특정 칸을 빠르게 찾게 해줍니다.
WHERE나 JOIN에 자주 쓰는 칸(FK 칸 등)에 만들면 좋습니다.
다만 데이터를 추가·수정할 때는 조금 더 느려질 수 있습니다.