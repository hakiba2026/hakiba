# المخطط التقني — حقيبة الأستاذ

## 1. هيكل المجلدات

```
/apps
  /web              -> واجهة الأستاذ (Next.js) - غلاف رفيع: تخطيط، توجيه، تحميل plugins المفعّلة
  /admin            -> لوحة تحكم المدير (مشروع Pages منفصل، نطاق فرعي منفصل)

/core
  /auth             -> تسجيل الدخول، الجلسات، RBAC
  /plugin-registry  -> تحميل/تفعيل/تعطيل plugins حسب صلاحية المستخدم
  /i18n             -> الترجمة AR/FR
  /db               -> عميل D1 + الترحيلات المشتركة (migrations)
  /storage          -> عميل R2
  /ui-kit           -> مكونات تصميم موحّدة، مُستخرجة ومُكيَّفة من قالب Shadcn Dashboard في /reference (راجع 05-design-system.md و 08-dashboard-template-integration.md)
  /queue            -> منطق jobs/Cron

/modules
  /lesson-generator   (manifest.ts, ui/, api/, schema.sql بادئة plg

## 2. قاعدة البيانات

Cloudflare D1 (SQLite) — المخطط الأولي في `07-db-schema.sql`. أهم المجموعات:
- المستخدمون والأدوار: `users`, `roles`, `user_roles`
- الباقات والاشتراكات: `plans`, `subscriptions`, `activation_codes`
- الصلاحيات/الإضافات: `plugins`, `plan_plugins`, `user_plugin_overrides`
- التصنيف الأكاديمي: `stages`, `branches`, `subjects`, `levels`, `units`
- الطابور: `jobs`
- التدقيق: `audit_log`

## 3. نظام الطابور (بدون تكلفة إضافية)

- جدول `jobs`: (id, type, payload_json, status [pending|processing|done|failed], retry_count, result_url, created_at, updated_at).
- عند طلب توليد (درس/تمرين/امتحان): إنشاء سطر `pending` فورًا، إرجاع استجابة سريعة للواجهة (لا حجب).
- **Cron Trigger** (كل دقيقة أو أقل) يفحص أعمال `pending`، ينفّذ استدعاء AI، يحدّث `status` و `result_url` (في R2 أو مباشرة في الجدول).
- عند فشل: زيادة `retry_count` بدل استخدام Dead Letter Queue (توفير التكلفة)، مع حد أقصى لإعادة المحاولة.
- الواجهة تستطلع (polling) حالة الـ job دوريًا حتى `done`/`failed` بدل WebSocket/Durable Object.

## 4. اتفاقيات API

- كل مسار تحت `/api/<module-key>/...`.
- كل مسار محمي بـ middleware: `requireAuth()` ثم `requirePlugin('<module-key>')` (للأستاذ) أو `requireRole('<role>')` (للمدير).
- التحقق من المدخلات عبر مخططات (schemas) صارمة (مثل zod) قبل أي كتابة في D1.
- استخدام Prepared Statements فقط في D1 (لا تجميع نصوص SQL يدويًا) لمنع SQL Injection.

## 5. خطة النشر

- مشروعا Cloudflare Pages منفصلان: `haqiba-web` (تطبيق الأستاذ) و `haqiba-admin` (لوحة المدير)، كل واحد بنطاقه الخاص (مثل `app.<domain>` و `admin.<domain>`).
- ربط كلا المشروعين بمستودع GitHub (فرع منفصل أو مجلد منفصل)، مع بناء تلقائي (CI) عند كل push.
- Cloudflare Access يُفعَّل فقط أمام نطاق `admin.<domain>` (راجع `06-security.md`).
- متغيرات البيئة/الأسرار تُضبط من لوحة Cloudflare (Pages > Settings > Environment variables) لكل مشروع على حدة، وليس في الكود.
