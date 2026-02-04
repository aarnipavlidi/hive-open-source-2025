CREATE TABLE IF NOT EXISTS spots (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  spot_id text UNIQUE NOT NULL,

  name text NOT NULL,
  operator text,
  contact_info text,

  address text,
  postal_code text,
  municipality text,
  post_office text,

  opening_hours_en text,
  opening_hours_fi text,
  opening_hours_sv text,

  description_en text,
  description_fi text,
  description_sv text,

  occupied boolean DEFAULT false,
  additional_details text,

  longitude double precision,
  latitude double precision,

  created_at timestamptz DEFAULT now()
);
