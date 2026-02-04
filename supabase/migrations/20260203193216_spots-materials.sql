CREATE TABLE spots_materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  spot_id text NOT NULL REFERENCES spots(spot_id) ON DELETE CASCADE,
  material_code integer NOT NULL REFERENCES materials(code) ON DELETE CASCADE,
  created_at timestamptz DEFAULT now(),
  UNIQUE (spot_id, material_code)
);
