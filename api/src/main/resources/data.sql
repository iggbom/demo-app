-- Idempotent seed — ON CONFLICT DO NOTHING makes this safe to run on every startup.
INSERT INTO items (name, description) VALUES
    ('Widget Alpha',   'A reliable all-purpose widget'),
    ('Widget Beta',    'A next-generation widget with extended features'),
    ('Widget Gamma',   'Compact widget optimised for low-power environments'),
    ('Widget Delta',   'Industrial-grade widget with enhanced durability'),
    ('Widget Epsilon', 'Experimental widget — handle with care')
ON CONFLICT (id) DO NOTHING;
