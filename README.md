# FIT4110_lab03_postman_mock_testing

**Học phần:** FIT4110 – Dịch vụ kết nối và Công nghệ nền tảng  
**Buổi 3:** Kiểm thử tích hợp với Postman + Mock Server  
**Case study:** Smart Campus Operations Platform  
**Artifact chính:** OpenAPI contract, Postman Collection, Environment mock/local, Newman report, Contract lint report, Reliability Checklist

---

## 1. Ý tưởng của lab

Ở **Lab 02**, mỗi nhóm đã thiết kế `openapi.yaml` như một **hợp đồng API**.  
Sang **Lab 03**, hợp đồng đó phải được biến thành **bộ kiểm thử có thể chạy được**.

> Tư duy chính: **API contract không chỉ để đọc, mà phải kiểm chứng được bằng test.**

Lab này mô phỏng tình huống thực tế trong hệ thống nhiều nhóm:

- Nhóm **Camera Stream** cần gọi **AI Vision**, nhưng AI Vision chưa code xong.
- Nhóm **Analytics** cần dữ liệu từ IoT, Camera, Core, nhưng các service chưa hoàn thiện.
- Nhóm **Core Business** cần kiểm thử luồng từ Access Gate / AI Vision / IoT, nhưng chưa thể chờ toàn bộ lớp xong code.

Giải pháp là dùng **OpenAPI + Mock Server + Postman + Newman + CI**:

1. Provider tạo mock từ `openapi.yaml`.
2. Consumer gọi vào mock để phát triển và kiểm thử sớm.
3. Provider viết Postman Collection để kiểm tra service của mình.
4. Newman chạy collection trên CLI / GitHub Actions để tạo evidence.
5. Contract được lint bằng Spectral hoặc Redocly trước khi chạy test.
6. Test được chạy trên 2 môi trường:
   - `mock`: kiểm thử contract khi service thật chưa xong.
   - `local`: kiểm thử service thật khi nhóm đã code xong.

---

## 2. Mục tiêu học tập

Sau lab này, sinh viên có thể:

- Import OpenAPI vào Postman và tạo collection có cấu trúc rõ ràng.
- Dùng Mock Server để mô phỏng provider API.
- Phân biệt rõ **mock behavior** và **real service behavior**.
- Viết test script bằng `pm.test`, kiểm tra status code, response body, schema cơ bản, auth, dữ liệu biên.
- Tổ chức environment `mock` và `local` đúng cách, không hardcode URL/token trong collection.
- Chạy collection bằng Newman và xuất report.
- Thực hiện consumer-side contract smoke test với mock của nhóm khác.
- Tích hợp contract lint và Newman vào CI.
- Nộp đủ evidence theo phong cách repo-based assessment.

---

## 3. Cấu trúc repo khuyến nghị

```text
FIT4110_lab03_postman_mock_testing/
├── README.md
├── package.json
├── Makefile
├── contracts/
│   ├── iot-ingestion.openapi.yaml
│   └── ai-vision.openapi.yaml                 # dùng cho consumer-side smoke test nếu cần
├── postman/
│   ├── collections/
│   │   └── FIT4110_lab03_iot_ingestion.postman_collection.json
│   └── environments/
│       ├── FIT4110_lab03_mock.postman_environment.json
│       └── FIT4110_lab03_local.postman_environment.json
├── mock-data/
│   ├── sensor-reading-valid.json
│   ├── sensor-reading-invalid-missing-device.json
│   └── sensor-reading-boundary.json
├── docs/
│   ├── TEAM_TASKS.md
│   ├── CONSUMER_SIDE_TESTING.md
│   └── GITHUB_ACTIONS_GUIDE.md
├── checklists/
│   ├── reliability_checklist.md
│   └── submission_checklist.md
├── templates/
│   ├── test-case-matrix.csv
│   └── consumer-provider-handshake.md
├── scripts/
│   ├── start-prism-mock.sh
│   └── run-newman.sh
├── reports/
│   └── .gitkeep
└── .github/
    └── workflows/
        └── newman.yml
```

> Nếu repo có thêm `docs/LAB_GUIDE.md`, cần đảm bảo file này tồn tại thật. Không liệt kê file chưa có trong README chính thức để tránh sinh viên bị lệch hướng.

---

## 4. Chuẩn bị môi trường

Yêu cầu khuyến nghị:

- Node.js `20.x` LTS.
- npm.
- Postman Desktop hoặc Postman Web.
- Git.

Cài dependencies:

```bash
npm install
```

Kiểm tra version:

```bash
node --version
npx newman --version
npx prism --version
```

---

## 5. Biến môi trường bắt buộc

Collection **không được hardcode** `baseUrl`, `authToken` hoặc URL mock của service khác trong collection variables.

Tất cả URL/token phải đặt trong Postman Environment.

| Biến | Mock environment | Local environment | Ý nghĩa |
|---|---|---|---|
| `env` | `mock` | `local` | Xác định môi trường đang chạy test |
| `baseUrl` | `http://localhost:4010` | `http://localhost:8000` | URL service chính của nhóm |
| `authToken` | `lab-token` | `local-dev-token` | Token/API key dùng cho request hợp lệ |
| `teamName` | `team-iot` | `team-iot` | Tên nhóm/service |
| `aiVisionMockUrl` | `http://localhost:4011` | `http://localhost:4011` | URL mock của service phụ thuộc, dùng cho consumer-side smoke test |

Ví dụ request URL trong Postman:

```text
{{baseUrl}}/readings
```

Ví dụ Authorization header:

```text
Authorization: Bearer {{authToken}}
```

---

## 6. Chạy Mock Server từ OpenAPI

Repo có contract mẫu cho **IoT Ingestion** tại:

```text
contracts/iot-ingestion.openapi.yaml
```

Chạy mock IoT bằng Prism:

```bash
npm run mock:iot
```

Mock server mặc định chạy tại:

```text
http://localhost:4010
```

Kiểm tra nhanh:

```bash
curl http://localhost:4010/health
```

Nếu cần consumer-side smoke test với **AI Vision**, tạo thêm contract tối giản:

```text
contracts/ai-vision.openapi.yaml
```

Và chạy mock Vision ở port khác:

```bash
npm run mock:vision
```

Ví dụ URL mock Vision:

```text
http://localhost:4011
```

---

## 7. Lưu ý quan trọng về Prism Mock

Prism Mock Server giúp sinh viên test sớm khi service thật chưa hoàn thiện, nhưng có giới hạn:

- Prism không thay thế hoàn toàn service thật.
- Prism có thể trả response dựa trên OpenAPI example.
- Prism không tự chứng minh logic nghiệp vụ, database, auth thật hoặc latency thật.
- Header `Prefer: code=XXX` là tính năng hỗ trợ mock của Prism, **không phải cách test HTTP chuẩn với service thật**.

Không dùng `Prefer: code=401` để chứng minh hệ thống có auth.

Test auth đúng phải tạo request thật sự thiếu hoặc sai token:

```javascript
pm.test("Unauthorized request returns 401 or 403", function () {
  pm.expect([401, 403]).to.include(pm.response.code);
});
```

Nếu mock trả `200` cho request thiếu token, test nên fail. Đây là tín hiệu đúng để sinh viên hiểu rằng mock chưa kiểm tra auth thật.

---

## 8. Chạy Postman Collection bằng Newman

Chạy với môi trường mock:

```bash
npm run test:mock
```

Chạy với môi trường local:

```bash
npm run test:local
```

Sau khi chạy, report được xuất vào:

```text
reports/
```

Ví dụ lệnh Newman trực tiếp:

```bash
npx newman run postman/collections/FIT4110_lab03_iot_ingestion.postman_collection.json \
  -e postman/environments/FIT4110_lab03_mock.postman_environment.json \
  -r cli,junit,htmlextra \
  --reporter-junit-export reports/newman-report.xml \
  --reporter-htmlextra-export reports/newman-report.html
```

---

## 9. Cấu trúc collection bắt buộc

Mỗi collection nên có ít nhất các folder sau:

```text
01_Functional
02_Auth
03_Negative
04_Boundary_Reliability
05_Consumer_side_Smoke
06_Local_only_NonFunctional
```

### 9.1 Functional

Kiểm thử happy path của API.

Ví dụ:

```javascript
pm.test("Status code is 201", function () {
  pm.response.to.have.status(201);
});

pm.test("Response has readingId", function () {
  const json = pm.response.json();
  pm.expect(json).to.have.property("readingId");
});
```

### 9.2 Auth

Kiểm thử request thiếu token, token sai, token hợp lệ.

Không ép mock trả `401` bằng `Prefer: code=401` rồi xem đó là auth test thật.

### 9.3 Negative

Kiểm thử payload sai, thiếu field bắt buộc, sai kiểu dữ liệu, sai query parameter.

Ví dụ:

```javascript
pm.test("Invalid payload returns client error", function () {
  pm.expect([400, 422]).to.include(pm.response.code);
});

pm.test("Error response follows ProblemDetails", function () {
  const json = pm.response.json();
  pm.expect(json).to.have.property("status");
  pm.expect(json.status).to.be.within(400, 599);
});
```

### 9.4 Boundary / Reliability

Không viết test kiểu chỉ kiểm tra request body có chứa giá trị đã gửi.

Ví dụ không nên dùng:

```javascript
pm.test("Boundary behavior is documented", function () {
  pm.expect(pm.request.body.raw).to.include("80");
});
```

Test boundary đúng cần kiểm tra phản hồi từ server.

Ví dụ:

```javascript
pm.test("High temperature is accepted with warning or rejected as invalid", function () {
  pm.expect([201, 400, 422]).to.include(pm.response.code);

  if (pm.response.code === 201) {
    pm.expect(pm.response.headers.has("X-Warning")).to.equal(true);
  }

  if ([400, 422].includes(pm.response.code)) {
    const json = pm.response.json();
    pm.expect(json).to.have.property("detail");
  }
});
```

### 9.5 Consumer-side Smoke

Consumer-side test phải gọi sang mock của **service phụ thuộc**, không chỉ gọi lại API của chính nhóm mình.

Ví dụ với IoT cần phụ thuộc AI Vision:

```text
POST {{aiVisionMockUrl}}/detect
```

Mục tiêu là kiểm tra consumer có thể hiểu contract tối thiểu của provider khác.

### 9.6 Local-only NonFunctional

Các test về latency/SLA chỉ nên chạy với service thật, không dùng để đánh giá mock.

Ví dụ:

```javascript
if (pm.environment.get("env") === "local") {
  pm.test("Response time is below 1000ms on local service", function () {
    pm.expect(pm.response.responseTime).to.be.below(1000);
  });
}
```

---

## 10. Quy trình thực hiện đề xuất

Sinh viên nên làm theo thứ tự sau:

1. Đọc lại `openapi.yaml` từ Lab 02.
2. Chạy contract lint bằng Spectral hoặc Redocly.
3. Import OpenAPI vào Postman.
4. Tạo collection theo 6 folder bắt buộc.
5. Tạo environment `mock`.
6. Chạy Prism Mock Server.
7. Chạy collection với Newman trên mock.
8. Tạo environment `local`.
9. Chạy lại collection trên service thật.
10. Chạy consumer-side smoke test với mock của ít nhất 1 nhóm phụ thuộc.
11. Xuất report.
12. Hoàn thiện checklist, test-case matrix và consumer-provider handshake.

---

## 11. Yêu cầu tối thiểu theo nhóm

Mỗi nhóm cần thay contract mẫu bằng contract của service mình từ Lab 02, sau đó tạo bộ test tương ứng.

| Nhóm | Số test tối thiểu | Bắt buộc có |
|---|---:|---|
| `team-iot` | 10 | POST reading, latest reading, auth, validation, boundary, rate limit |
| `team-camera` | 10 | upload frame, trigger analyze, invalid image, callback/mock AI Vision |
| `team-gate` | 10 | access event, allow/deny, invalid card, auth |
| `team-vision` | 10 | detect image, model info, invalid image_url/base64, confidence boundary |
| `team-analytics` | 10 | ingest event, aggregate metric, missing time range, multi-source smoke |
| `team-core` | 10 | evaluate sensor/access/detection, policy not found, alert creation |
| `team-notify` | 10 | send notification, retry, dedupe, invalid channel, upstream alert mock |

Một request có thể có nhiều `pm.test`, nhưng điểm sẽ ưu tiên **ý nghĩa kiểm thử**, không chỉ đếm số lượng assertion.

---

## 12. Yêu cầu chất lượng OpenAPI contract

Contract của mỗi nhóm phải đảm bảo:

- Mỗi operation có ít nhất một response thành công `2xx` và một response lỗi `4xx`.
- Các query parameter có `minimum`, `maximum`, `enum` hoặc `pattern` khi phù hợp.
- Error response nên dùng cấu trúc tương thích `ProblemDetails`.
- `ProblemDetails.status` phải có `minimum: 400` và `maximum: 599`.
- API có khả năng bị flood nên cân nhắc response `429 Too Many Requests`.
- Field dạng enum nghiệp vụ phải được ràng buộc rõ.

Ví dụ với IoT reading:

```yaml
metric:
  type: string
  enum: [temperature, humidity, motion, smoke]

unit:
  type: string
  enum: [celsius, percent, boolean, ppm]
```

Nếu muốn ràng buộc chặt hơn giữa `metric` và `unit`, dùng `oneOf`.

Ví dụ response lỗi:

```yaml
ProblemDetails:
  type: object
  required: [type, title, status]
  properties:
    type:
      type: string
    title:
      type: string
    status:
      type: integer
      minimum: 400
      maximum: 599
    detail:
      type: string
```

---

## 13. Data-driven testing với mock-data

Các file trong `mock-data/` không nên chỉ để minh họa. Nên dùng chúng trong Newman bằng iteration data hoặc tham chiếu rõ trong test-case matrix.

Ví dụ chạy Newman với data file:

```bash
npx newman run postman/collections/FIT4110_lab03_iot_ingestion.postman_collection.json \
  -e postman/environments/FIT4110_lab03_mock.postman_environment.json \
  --iteration-data mock-data/sensor-reading-valid.json
```

Nếu collection nhúng JSON inline trong `body.raw`, cần đảm bảo `templates/test-case-matrix.csv` không ghi lệch sang file dữ liệu ngoài mà collection không dùng.

---

## 14. CI khuyến nghị

CI nên chạy theo thứ tự:

1. Install dependencies.
2. Lint OpenAPI contract.
3. Start Prism mock server.
4. Wait until mock server is ready.
5. Run Newman.
6. Upload report artifact.
7. Cleanup mock server nếu cần.

Ví dụ GitHub Actions:

```yaml
name: Contract and Newman Tests

on:
  push:
  pull_request:

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v4

      - uses: actions/setup-node@v4
        with:
          node-version: "20"
          cache: "npm"

      - name: Install dependencies
        run: npm ci

      - name: Lint OpenAPI contracts
        run: npx @stoplight/spectral-cli lint contracts/*.yaml

      - name: Start Prism mock server
        run: nohup npm run mock:iot > prism.log 2>&1 &

      - name: Wait for mock server
        run: npx wait-on http://localhost:4010/health --timeout 30000

      - name: Run Newman on mock environment
        run: npm run test:mock

      - name: Show Prism log on failure
        if: failure()
        run: cat prism.log || true

      - name: Upload Newman reports
        if: always()
        uses: actions/upload-artifact@v4
        with:
          name: newman-reports
          path: reports/
```

Không nên chỉ dùng `sleep 5` để đợi mock server vì máy CI có thể chậm hoặc Prism chưa sẵn sàng.

---

## 15. Artifact phải nộp

Nộp vào repo nhóm hoặc LMS:

- `contracts/<team>.openapi.yaml`
- `postman/collections/<team>.postman_collection.json`
- `postman/environments/<team>_mock.postman_environment.json`
- `postman/environments/<team>_local.postman_environment.json`
- `reports/newman-report.xml` hoặc `reports/newman-report.html`
- `reports/contract-lint-report.txt` hoặc log CI chứng minh contract lint pass
- `checklists/reliability_checklist.md`
- `templates/test-case-matrix.csv` đã điền
- `templates/consumer-provider-handshake.md` đã điền với ít nhất 1 nhóm phụ thuộc
- Link GitHub Actions run hoặc ảnh chụp/log CLI chứng minh test chạy được

---

## 16. Definition of Done

Một nhóm được xem là hoàn thành Lab 03 khi:

- Contract lint pass hoặc có giải thích rõ warning còn lại.
- Collection chạy pass trên mock environment.
- Collection chạy pass trên local environment, hoặc có ghi chú rõ endpoint nào chưa hoàn thiện và lý do.
- Collection không hardcode `baseUrl` hoặc `authToken`.
- Có test cho happy path, auth, negative, boundary/reliability.
- Có ít nhất 1 consumer-side smoke test gọi mock của service phụ thuộc.
- Newman report được sinh trong thư mục `reports/`.
- Test-case matrix map được từng test với endpoint, input, expected status và loại test.
- Reliability checklist và consumer-provider handshake đã hoàn thiện.

---

## 17. Quy tắc đánh giá

| Tiêu chí | Điểm | Mô tả đạt tối đa |
|---|---:|---|
| Chất lượng OpenAPI contract | 1.5 | Contract lint pass, có schema rõ, có response lỗi, có ràng buộc enum/range phù hợp |
| Collection có cấu trúc rõ ràng | 1.5 | Có folder Functional/Auth/Negative/Boundary/Consumer-side/Local-only, đặt tên request dễ hiểu |
| Test coverage | 2.5 | Có happy path, auth, validation error, boundary, response body/schema, không test kiểu tautology |
| Mock và local environment | 1.5 | Cùng collection chạy được trên cả mock và local, không hardcode URL/token trong collection |
| Newman report và CI evidence | 1.5 | Có report XML/HTML, có log hoặc GitHub Actions chạy contract lint + Newman |
| Consumer-side smoke test | 1.0 | Có test gọi mock của ít nhất 1 service phụ thuộc và có biên bản handshake |
| Checklist và test-case matrix | 0.5 | Điền đủ reliability checklist và test-case matrix |
| **Tổng** | **10.0** | |

---

## 18. Lỗi thường gặp

| Lỗi | Nguyên nhân thường gặp | Cách xử lý |
|---|---|---|
| `ECONNREFUSED` | Mock server chưa chạy | Chạy `npm run mock:iot` và kiểm tra `/health` |
| Newman chạy vào mock dù muốn test local | Environment local chưa được load hoặc collection còn hardcode `baseUrl` | Kiểm tra `-e <local_environment>` và xoá collection variable gây nhầm |
| `401 Unauthorized` khi chạy happy path | Thiếu hoặc sai `authToken` | Kiểm tra environment variable và Authorization header |
| Test auth pass trên mock nhưng fail trên local | Mock không validate auth thật | Viết rõ kỳ vọng và chạy lại trên service thật |
| Test pass trên mock nhưng fail trên local | Service thật chưa đúng contract | So sánh response với OpenAPI và Newman report |
| Boundary test không có ý nghĩa | Test đang kiểm request body thay vì response | Chuyển sang assert status code, error body, warning header hoặc business rule |
| CI fail vì port 4010 bận | Mock process cũ chưa cleanup, thường gặp trên self-hosted runner | Cleanup process hoặc đổi port |
| Spectral lint fail | Contract thiếu response lỗi, schema thiếu ràng buộc, naming chưa đúng | Sửa OpenAPI trước khi chạy Newman |

---

## 19. Gợi ý `.gitignore`

```gitignore
node_modules/
.env
.DS_Store
prism.log
reports/*.xml
reports/*.html
reports/*.json
!reports/.gitkeep
```

---

## 20. Tinh thần của buổi học

> Sau Buổi 2, chúng ta có **hợp đồng API**.  
> Sau Buổi 3, hợp đồng đó trở thành **bộ kiểm thử có bằng chứng**.  
> Từ đây, mỗi lần sửa service, nhóm phải chứng minh: API vẫn đúng contract, consumer vẫn gọi được, lỗi được xử lý có kiểm soát, và evidence có thể chạy lại trên CI.
