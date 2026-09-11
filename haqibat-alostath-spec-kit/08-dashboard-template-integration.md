# دمج قالب لوحة التحكم (Shadcn Dashboard) — حقيبة الأستاذ

> هذا الملف يوثّق القالب المرفق (`next-shadcn-dashboard-main.zip`) وكيفية استعماله في كلا التطبيقين (`apps/web` و `apps/admin`). اقرأه قبل بناء أي واجهة، وقبل تطبيق تفاصيل `05-design-system.md`.

## 1. ما هو هذا القالب

**Shadcn Dashboard** — قالب Next.js (App Router) جاهز ومفتوح المصدر:
- Next.js 16 + React 19، Tailwind CSS v4، shadcn/ui، Base UI.
- يتضمن: لوحة تحكم بإحصائيات/رسوم بيانية (Recharts)، تطبيقات جاهزة (Blog، Notes، Tickets)، صفحات مصادقة كاملة (تسجيل دخول/تسجيل/نسيت كلمة السر/OTP/مصادقة ثنائية)، نماذج وجداول بيانات (`@tanstack/react-table`)، صفحة ملف شخصي، دعم الوضع الداكن (`next-themes`)، ومكتبة مكوّنات UI غنية.
- مصمَّم Responsive/Mobile-First أصلًا، ويستعمل pnpm لإدارة الحزم.

## 2. أين تجده وأين يوضع

ضع محتوى الملف المضغوط (بعد فك الضغط) في `/reference/shadcn-dashboard-template/` داخل مستودع الكود. هذا المجلد **مرجع للدراسة والاستخراج فقط** — لا يُشغَّل أو يُنشر كتطبيق قائم بذاته في الإنتاج.

## 3. بنية القالب المهمة لنا

```
next-shadcn-dashboard-main/
  app/
    (dashboard-layout)/         -> غلاف اللوحة (Sidebar + Header)، هذا هو الأهم لنا
      layout.tsx                -> تخطيط اللوحة الكامل
      layout/
        shared/breadcrumb/      -> مكوّن Breadcrumb
        shared/header/          -> عناصر مشتركة للهيدر
        shared/logo/            -> الشعار
        vertical/header/        -> الهيدر الثابت
        vertical/sidebar/
          app-sidebar.tsx        -> المكوّن الرئيسي للـ Sidebar
          nav-items/index.tsx    -> منطق عرض عناصر القائمة
          nav-user.tsx           -> قسم المستخدم أسفل الشريط
          sidebaritems.ts        -> تعريف عناصر القائمة (نستبدله بمنطقنا الديناميكي)
        vertical/footer/
    auth/
      authforms/                -> تسجيل الدخول/التسجيل/نسيت كلمة السر (مرجع تصميم فقط)
      auth2/                     -> صفحات المصادقة الثنائية (مرجع لتفعيل 2FA لدينا)
    api/                        -> أمثلة مسارات API (ليست جزءًا من منطقنا، مرجع بنية فقط)
    components/
      dashboards/                -> بطاقات إحصائيات/رسوم — مرجع لبطاقات لوحة المدير
      tables/                    -> جدول بيانات جاهز (نستعمله لكل الجداول: مستخدمون، اشتراكات...)
  components/ui/                -> أساسيات shadcn/ui (button, dialog, select, sidebar, sheet, table, tabs, direction...)
  hooks/, lib/                  -> أدوات مساعدة عامة
```

## 4. خطوات التكييف (لـ antigravity)

1. **الاستخراج، لا الاستيراد الكامل**: لا تُنسخ كل مجلد `app/` من القالب إلى تطبيقاتنا. تُستخرج فقط:
   - كل `components/ui/*` (أساسيات shadcn/ui) → `core/ui-kit/primitives/`.
   - غلاف اللوحة (`(dashboard-layout)/layout.tsx` + `layout/vertical/*` + `layout/shared/*`) → يُعاد بناؤه كمكوّن `AppShell` واحد في `core/ui-kit/shell/`، يستورده كل من `apps/web` و `apps/admin`.
   - مكوّن `components/tables` (جدول عام) → `core/ui-kit/data-table/`.
   - صفحات `auth/authforms` و `auth/auth2` → مرجع تصميم بصري فقط؛ منطق المصادقة الفعلي يُبنى في `core/auth` حسب `06-security.md` (JWT قصير الأمد، Refresh Token، 2FA حقيقي) — لا تُستعمل أي منطق مصادقة زائف موجود في القالب كما هو.
2. **RTL/LTR**: فعّل `components/ui/direction.tsx` (`DirectionProvider`) في `AppShell`، مرتبطًا بلغة الواجهة الحالية (`core/i18n`)، بدل أي كود شرطي يدوي لكل عنصر.
3. **Sidebar الديناميكي**: استبدل `sidebaritems.ts` الثابت بدالة تبني القائمة من:
   - في `apps/web`: قائمة الـ plugins المفعّلة فعليًا للمستخدم (`core/plugin-registry`).
   - في `apps/admin`: قائمة شاشات الإدارة الثابتة (المستخدمون، الباقات، الاشتراكات...).
4. **تبسيط**: لا تُدرج تطبيقات Blog/Notes/Tickets التجريبية في أي مسار إنتاج. يمكن دراسة `Tickets` لاحقًا كمرجع لموديول "دعم فني" مستقل تحت `/modules` إن قرّرنا إضافته (قرار مستقبلي، اسأل قبل التنفيذ).
5. **الالتزام البصري**: أي مكوّن واجهة جديد (نماذج التوليد، بطاقات الأسعار، الجدول...) يجب أن يستعمل أساسيات القالب (`Button`, `Card`, `Dialog`, `Table`, `Tabs`...) بنفس نظام الألوان/الخطوط/المسافات، ولا يخترع نمطًا بصريًا مختلفًا.

## 5. لوحة المدير مقابل لوحة الأستاذ

كلا التطبيقين يستوردان **نفس** `AppShell` من `core/ui-kit`. الاختلاف الوحيد بينهما هو محتوى Sidebar (شاشات إدارة ثابتة في `apps/admin`، أدوات/plugins ديناميكية في `apps/web`) ولون/شعار مميّز اختياري لتمييز لوحة المدير بصريًا عن لوحة الأستاذ (مثل شارة "Admin" في الهيدر).

## 6. معيار الجودة

الهدف: أن تبدو المنصة "منصة عالمية" حسب طلب مالك المشروع — أي أن تستفيد فعليًا من جودة القالب المرفق (تفاصيل الحركة/الانتقالات عبر `framer-motion`/`motion`، الرسوم البيانية عبر `recharts`، وضع داكن كامل) بدل تبسيطها لشكل عام غير مصقول.
