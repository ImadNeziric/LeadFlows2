# LeadFlow MVP Starter

Includes `index.html`, `styles.css`, `app.js`, and `schema.sql` (Supabase database, access policies, public form submission functions).

## A. Configure Supabase
1. Create a Supabase project at https://supabase.com.
2. Open **SQL Editor**, paste all of `schema.sql`, and run it.
3. Open the project's API settings and copy the **Project URL** and **publishable key** (older projects may call this the `anon` key).
4. In `index.html`, replace `PASTE_SUPABASE_PROJECT_URL_HERE` and `PASTE_SUPABASE_PUBLISHABLE_OR_ANON_KEY_HERE` with those values.
5. Never put a `service_role` or secret key in browser code.
6. In Supabase Auth URL configuration, set your local/deployed site URL and allowed redirect URLs. Email confirmation may be enabled; confirm the account before signing in.

## B. Test it
1. Open `index.html` through a local server or deploy it to Vercel.
2. Create an account and sign in.
3. Change the business name and slug, then save.
4. Copy the public form link and open it in a private/incognito window.
5. Submit a test inquiry. Go back to the dashboard and verify it appears.
6. Open the lead, set its status to `won`, enter the won-job value, and save.
7. Confirm the analytics update and test CSV export.

## C. Publish with Vercel
1. Create a GitHub repository and upload `index.html`.
2. In Vercel, import that repository and deploy it as a static site (no build command required).
3. After deploy, set the production URL in Supabase Auth URL configuration.
4. Create a new account on the live URL and test the complete public-form-to-dashboard workflow.

## MVP scope / production hardening
- Included: email/password auth, one workspace per account, RLS-protected leads, shareable form, lead status management, estimated/won values, date filters, source summary, CSV export.
- Not included: teams/roles, subscription billing, email notifications, phone/SMS integration, audit logs, data-retention automation, custom domains, and robust rate limiting/CAPTCHA.
- The public form has input validation and a honeypot but that is not full spam protection. Before advertising widely, add rate limiting/CAPTCHA (for example via an Edge Function) and a privacy policy/retention process.
- Test access with two separate accounts before storing real customer data. Avoid collecting sensitive data in free-text fields.
- This is a functional starter, not a security audit or guarantee of production readiness.
