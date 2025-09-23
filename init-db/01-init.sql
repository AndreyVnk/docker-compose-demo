-- DB initializaton

-- Creating visits table
CREATE TABLE IF NOT EXISTS visits (
    id SERIAL PRIMARY KEY,
    timestamp TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    message TEXT NOT NULL,
    ip_address INET,
    user_agent TEXT
);

-- Creating an index for quick date identification
CREATE INDEX IF NOT EXISTS idx_visits_timestamp ON visits(timestamp);

-- Inserting text data
INSERT INTO visits (message, ip_address, user_agent) VALUES 
    ('Initial setup visit', '127.0.0.1', 'Docker Setup'),
    ('Health check', '127.0.0.1', 'Health Monitor'),
    ('Demo data', '192.168.1.1', 'Demo Browser');

-- Create a function to purge old records (older than 30 days)
CREATE OR REPLACE FUNCTION cleanup_old_visits()
RETURNS void AS $$
BEGIN
    DELETE FROM visits 
    WHERE timestamp < NOW() - INTERVAL '30 days';
END;
$$ LANGUAGE plpgsql;

-- Creating statistics presentation
CREATE OR REPLACE VIEW daily_visit_stats AS
SELECT 
    DATE(timestamp) as visit_date,
    COUNT(*) as visit_count,
    COUNT(DISTINCT ip_address) as unique_visitors
FROM visits
GROUP BY DATE(timestamp)
ORDER BY visit_date DESC;
