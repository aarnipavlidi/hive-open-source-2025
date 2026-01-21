CREATE TYPE recycling_material_type AS ENUM (
  'Biojäte',
  'Poistotekstiili',
  'Rakennus- ja purkujäte',
  'Kyllästetty puu',
  'Puu',
  'Lamput',
  'Ajoneuvoakut (lyijy)',
  'Muu jäte',
  'Tekstiili',
  'Muovi',
  'Kannettavat akut ja paristot',
  'Sähkölaitteet (SER)',
  'Vaarallinen jäte',
  'Lasi',
  'Metalli',
  'Kartonki',
  'Pahvi',
  'Paperi',
  'Energiajäte',
  'Puutarhajäte',
  'Sekajäte'
);

CREATE TABLE IF NOT EXISTS materials (
  id uuid PRIMARY KEY DEFAULT gen_random_uuid(),
  code integer UNIQUE NOT NULL,
  name recycling_material_type NOT NULL,
  created_at timestamptz DEFAULT now()
);
