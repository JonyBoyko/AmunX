CREATE TYPE billing_provider AS ENUM('stripe','revenuecat','monopay');
CREATE TYPE subscription_status AS ENUM('trialing','active','past_due','canceled','expired');

CREATE TABLE billing_products (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  code TEXT UNIQUE NOT NULL,
  name TEXT NOT NULL,
  description TEXT,
  provider billing_provider NOT NULL,
  external_id TEXT,
  currency TEXT NOT NULL,
  amount_cents INT NOT NULL,
  interval TEXT NOT NULL CHECK (interval IN ('month','year')),
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  active BOOLEAN NOT NULL DEFAULT TRUE,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE user_subscriptions (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  product_id UUID REFERENCES billing_products(id),
  provider billing_provider NOT NULL,
  status subscription_status NOT NULL,
  started_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  current_period_end TIMESTAMPTZ,
  cancel_at TIMESTAMPTZ,
  canceled_at TIMESTAMPTZ,
  external_customer_id TEXT,
  external_subscription_id TEXT,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (provider, external_subscription_id)
);
CREATE INDEX user_subscriptions_user_idx ON user_subscriptions(user_id, status);

CREATE TABLE billing_entitlements (
  id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
  user_id UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
  code TEXT NOT NULL,
  source billing_provider NOT NULL,
  status TEXT NOT NULL CHECK (status IN ('active','revoked')),
  expires_at TIMESTAMPTZ,
  metadata JSONB NOT NULL DEFAULT '{}'::jsonb,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  updated_at TIMESTAMPTZ NOT NULL DEFAULT now(),
  UNIQUE (user_id, code)
);
CREATE INDEX billing_entitlements_user_idx ON billing_entitlements(user_id, status);

CREATE TABLE billing_payment_events (
  id BIGSERIAL PRIMARY KEY,
  user_id UUID REFERENCES users(id) ON DELETE SET NULL,
  provider billing_provider NOT NULL,
  event_type TEXT,
  external_id TEXT,
  amount_cents INT,
  currency TEXT,
  payload JSONB NOT NULL,
  created_at TIMESTAMPTZ NOT NULL DEFAULT now()
);
CREATE INDEX billing_payment_events_provider_idx ON billing_payment_events(provider, created_at DESC);

INSERT INTO billing_products (code, name, description, provider, external_id, currency, amount_cents, interval)
VALUES
  ('pro_monthly', 'Pro Monthly', 'Full access to AI + live features (Stripe)', 'stripe', 'price_stripe_monthly_placeholder', 'USD', 1500, 'month'),
  ('pro_annual', 'Pro Annual', '2 months free when paying yearly (Stripe)', 'stripe', 'price_stripe_annual_placeholder', 'USD', 15000, 'year'),
  ('pro_mobile_monthly', 'Pro Mobile Monthly', 'In-app purchase via RevenueCat', 'revenuecat', 'prod_revenuecat_monthly_placeholder', 'USD', 1500, 'month'),
  ('pro_ua_monthly', 'Pro UA Monthly', 'MonoPay billing for Ukraine', 'monopay', 'monopay_plan_monthly_placeholder', 'UAH', 5900, 'month')
ON CONFLICT (code) DO NOTHING;

