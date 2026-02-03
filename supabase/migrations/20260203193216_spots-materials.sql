CREATE TABLE IF NOT EXISTS spots_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),

  spot_id uuid NOT NULL REFERENCES spots(id) ON DELETE CASCADE,
  material_id uuid NOT NULL REFERENCES materials(id) ON DELETE CASCADE,

  created_at timestamptz DEFAULT now(),

  UNIQUE (spot_id, material_id)
);
