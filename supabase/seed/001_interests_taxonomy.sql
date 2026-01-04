-- ============================================================================
-- INTEREST TAXONOMY SEED DATA
-- ============================================================================
-- This seed data provides a comprehensive taxonomy of 150+ interests
-- organized into 12 categories for travelers and digital nomads
-- ============================================================================

-- Insert Interest Categories
INSERT INTO interest_categories (name, slug, description, icon, sort_order) VALUES
('Food & Dining', 'food-dining', 'Culinary experiences and dining preferences', '🍽️', 1),
('Outdoor & Adventure', 'outdoor-adventure', 'Hiking, sports, and outdoor activities', '🏔️', 2),
('Arts & Culture', 'arts-culture', 'Museums, galleries, music, and cultural events', '🎨', 3),
('Coworking & Professional', 'coworking-professional', 'Work-related activities and networking', '💼', 4),
('Sports & Fitness', 'sports-fitness', 'Physical activities and wellness', '⚽', 5),
('Nightlife & Social', 'nightlife-social', 'Bars, clubs, and social gatherings', '🍻', 6),
('Learning & Education', 'learning-education', 'Workshops, classes, and skill development', '📚', 7),
('Wellness & Mindfulness', 'wellness-mindfulness', 'Yoga, meditation, and self-care', '🧘', 8),
('Technology & Gaming', 'technology-gaming', 'Tech meetups, gaming, and digital culture', '💻', 9),
('Community & Volunteering', 'community-volunteering', 'Social impact and community service', '🤝', 10),
('Entertainment & Hobbies', 'entertainment-hobbies', 'Movies, shows, and recreational activities', '🎭', 11),
('Travel & Exploration', 'travel-exploration', 'Sightseeing and travel experiences', '✈️', 12);

-- Insert Interests

-- Food & Dining (20 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Fine Dining', 'fine-dining', 'High-end restaurant experiences'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Street Food', 'street-food', 'Local street food and market exploration'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Vegan/Vegetarian', 'vegan-vegetarian', 'Plant-based dining'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Coffee Culture', 'coffee-culture', 'Specialty coffee and café hopping'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Wine Tasting', 'wine-tasting', 'Wine bars and vineyard visits'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Craft Beer', 'craft-beer', 'Brewery tours and tastings'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Cooking Classes', 'cooking-classes', 'Learning local cuisine'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Food Markets', 'food-markets', 'Fresh markets and food halls'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Brunch', 'brunch', 'Weekend brunch spots'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Bakeries & Pastries', 'bakeries-pastries', 'Artisan bakeries'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Seafood', 'seafood', 'Fresh seafood experiences'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'BBQ & Grilling', 'bbq-grilling', 'Barbecue and grilled food'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Asian Cuisine', 'asian-cuisine', 'Asian food exploration'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Italian Cuisine', 'italian-cuisine', 'Pizza, pasta, and Italian food'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Mexican Cuisine', 'mexican-cuisine', 'Tacos, tamales, and Mexican food'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Desserts & Sweets', 'desserts-sweets', 'Ice cream, chocolate, and desserts'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Food Trucks', 'food-trucks', 'Mobile food vendors'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Farm-to-Table', 'farm-to-table', 'Local and sustainable dining'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Tea Culture', 'tea-culture', 'Tea houses and ceremonies'),
((SELECT id FROM interest_categories WHERE slug = 'food-dining'), 'Cocktail Bars', 'cocktail-bars', 'Mixology and cocktail culture');

-- Outdoor & Adventure (18 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Hiking', 'hiking', 'Trail hiking and mountain walks'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Rock Climbing', 'rock-climbing', 'Indoor and outdoor climbing'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Surfing', 'surfing', 'Wave riding and beach culture'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Scuba Diving', 'scuba-diving', 'Underwater exploration'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Kayaking/Canoeing', 'kayaking-canoeing', 'Water paddle sports'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Mountain Biking', 'mountain-biking', 'Off-road cycling'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Camping', 'camping', 'Outdoor camping experiences'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Beach Activities', 'beach-activities', 'Beach sports and relaxation'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Skiing/Snowboarding', 'skiing-snowboarding', 'Winter sports'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Trail Running', 'trail-running', 'Off-road running'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Wildlife Photography', 'wildlife-photography', 'Nature and animal photography'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Birdwatching', 'birdwatching', 'Bird observation and identification'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Stand-Up Paddling', 'stand-up-paddling', 'SUP boarding'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Paragliding', 'paragliding', 'Aerial adventure sports'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Zip-lining', 'zip-lining', 'Canopy tours and zip lines'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Hot Air Ballooning', 'hot-air-ballooning', 'Balloon rides'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Snorkeling', 'snorkeling', 'Surface water exploration'),
((SELECT id FROM interest_categories WHERE slug = 'outdoor-adventure'), 'Fishing', 'fishing', 'Sport and recreational fishing');

-- Arts & Culture (16 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Museums', 'museums', 'Art and history museums'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Art Galleries', 'art-galleries', 'Contemporary art spaces'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Live Music', 'live-music', 'Concerts and live performances'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Jazz', 'jazz', 'Jazz clubs and performances'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Classical Music', 'classical-music', 'Orchestra and classical concerts'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Theater', 'theater', 'Plays and theatrical performances'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Opera', 'opera', 'Opera performances'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Street Art', 'street-art', 'Graffiti and urban art'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Photography', 'photography', 'Photo walks and exhibitions'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Film & Cinema', 'film-cinema', 'Movies and film festivals'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Architecture', 'architecture', 'Building tours and design'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Local History', 'local-history', 'Historical sites and stories'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Cultural Festivals', 'cultural-festivals', 'Traditional celebrations'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Dance', 'dance', 'Dance performances and classes'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Poetry & Literature', 'poetry-literature', 'Book clubs and readings'),
((SELECT id FROM interest_categories WHERE slug = 'arts-culture'), 'Crafts & DIY', 'crafts-diy', 'Handmade arts and crafts');

-- Coworking & Professional (12 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Coworking Spaces', 'coworking-spaces', 'Shared workspaces'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Networking Events', 'networking-events', 'Professional networking'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Startup Culture', 'startup-culture', 'Entrepreneurship and startups'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Digital Nomad Meetups', 'digital-nomad-meetups', 'Remote worker gatherings'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Business Development', 'business-development', 'B2B and growth discussions'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Marketing', 'marketing', 'Marketing strategy and tactics'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Design', 'design', 'UI/UX and graphic design'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Tech Talks', 'tech-talks', 'Technology presentations'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Freelancing', 'freelancing', 'Independent work discussions'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Project Management', 'project-management', 'PM methodologies and tools'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Writing & Blogging', 'writing-blogging', 'Content creation'),
((SELECT id FROM interest_categories WHERE slug = 'coworking-professional'), 'Public Speaking', 'public-speaking', 'Presentation skills');

-- Sports & Fitness (14 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Gym & Weight Training', 'gym-weight-training', 'Strength training'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'CrossFit', 'crossfit', 'CrossFit workouts'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Running', 'running', 'Road running and jogging'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Cycling', 'cycling', 'Road and city cycling'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Swimming', 'swimming', 'Pool and open water swimming'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Tennis', 'tennis', 'Tennis games and lessons'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Soccer/Football', 'soccer-football', 'Pickup games and matches'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Basketball', 'basketball', 'Pickup basketball'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Volleyball', 'volleyball', 'Beach and indoor volleyball'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Martial Arts', 'martial-arts', 'MMA, boxing, jiu-jitsu'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Pilates', 'pilates', 'Pilates classes'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Barre', 'barre', 'Barre fitness'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'HIIT Workouts', 'hiit-workouts', 'High-intensity training'),
((SELECT id FROM interest_categories WHERE slug = 'sports-fitness'), 'Dance Fitness', 'dance-fitness', 'Zumba and dance workouts');

-- Nightlife & Social (12 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Dance Clubs', 'dance-clubs', 'Electronic and dance music'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Live DJ Sets', 'live-dj-sets', 'DJ performances'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Karaoke', 'karaoke', 'Singing and karaoke bars'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Pub Crawls', 'pub-crawls', 'Bar hopping'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Trivia Nights', 'trivia-nights', 'Quiz competitions'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Comedy Shows', 'comedy-shows', 'Stand-up comedy'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Rooftop Bars', 'rooftop-bars', 'Sky bars and lounges'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Sports Bars', 'sports-bars', 'Watching sports at bars'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Game Nights', 'game-nights', 'Board games and card games'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Speed Friending', 'speed-friending', 'Quick social meetups'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Language Exchange', 'language-exchange', 'Practice languages socially'),
((SELECT id FROM interest_categories WHERE slug = 'nightlife-social'), 'Social Dancing', 'social-dancing', 'Salsa, bachata, swing');

-- Learning & Education (11 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Language Classes', 'language-classes', 'Learning new languages'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Coding Bootcamps', 'coding-bootcamps', 'Programming education'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Photography Workshops', 'photography-workshops', 'Photo technique classes'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Art Classes', 'art-classes', 'Painting and drawing'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Music Lessons', 'music-lessons', 'Instrument or vocal training'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Dance Classes', 'dance-classes', 'Dance instruction'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Cooking Workshops', 'cooking-workshops', 'Culinary skill building'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Personal Development', 'personal-development', 'Self-improvement seminars'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Book Clubs', 'book-clubs', 'Reading groups'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'History Tours', 'history-tours', 'Guided historical walks'),
((SELECT id FROM interest_categories WHERE slug = 'learning-education'), 'Science & Tech', 'science-tech', 'STEM learning');

-- Wellness & Mindfulness (10 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Yoga', 'yoga', 'Yoga classes and practice'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Meditation', 'meditation', 'Mindfulness meditation'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Breathwork', 'breathwork', 'Breathing exercises'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Spa & Massage', 'spa-massage', 'Relaxation and treatments'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Acupuncture', 'acupuncture', 'Traditional medicine'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Sound Healing', 'sound-healing', 'Sound baths and therapy'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Reiki', 'reiki', 'Energy healing'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Tai Chi', 'tai-chi', 'Moving meditation'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Nutrition', 'nutrition', 'Healthy eating and diet'),
((SELECT id FROM interest_categories WHERE slug = 'wellness-mindfulness'), 'Mental Health', 'mental-health', 'Well-being discussions');

-- Technology & Gaming (10 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Web Development', 'web-development', 'Frontend and backend dev'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Mobile Development', 'mobile-development', 'iOS and Android'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'AI & Machine Learning', 'ai-machine-learning', 'Artificial intelligence'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Blockchain & Crypto', 'blockchain-crypto', 'Web3 and cryptocurrency'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Video Games', 'video-games', 'Gaming and esports'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Board Games', 'board-games', 'Tabletop gaming'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Virtual Reality', 'virtual-reality', 'VR experiences'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Robotics', 'robotics', 'Hardware and automation'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Cybersecurity', 'cybersecurity', 'Information security'),
((SELECT id FROM interest_categories WHERE slug = 'technology-gaming'), 'Data Science', 'data-science', 'Analytics and visualization');

-- Community & Volunteering (8 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Environmental Conservation', 'environmental-conservation', 'Eco projects'),
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Animal Welfare', 'animal-welfare', 'Animal rescue and care'),
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Teaching/Tutoring', 'teaching-tutoring', 'Educational volunteering'),
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Community Gardens', 'community-gardens', 'Urban gardening'),
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Beach Cleanups', 'beach-cleanups', 'Environmental cleanup'),
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Food Banks', 'food-banks', 'Hunger relief'),
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Mentorship', 'mentorship', 'Guiding others'),
((SELECT id FROM interest_categories WHERE slug = 'community-volunteering'), 'Social Justice', 'social-justice', 'Activism and advocacy');

-- Entertainment & Hobbies (10 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Podcasting', 'podcasting', 'Creating and listening to podcasts'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Music Production', 'music-production', 'Making music'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'DJing', 'djing', 'DJ skills and performances'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Gardening', 'gardening', 'Plant care and growing'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Vintage Shopping', 'vintage-shopping', 'Thrift stores and antiques'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Fashion', 'fashion', 'Style and clothing'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Astrology', 'astrology', 'Zodiac and horoscopes'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Tarot', 'tarot', 'Card reading'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Poker', 'poker', 'Card games and tournaments'),
((SELECT id FROM interest_categories WHERE slug = 'entertainment-hobbies'), 'Chess', 'chess', 'Strategy game');

-- Travel & Exploration (9 interests)
INSERT INTO interests (category_id, name, slug, description) VALUES
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'City Walking Tours', 'city-walking-tours', 'Urban exploration'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Day Trips', 'day-trips', 'Short excursions'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Road Trips', 'road-trips', 'Multi-day driving adventures'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Backpacking', 'backpacking', 'Budget travel'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Luxury Travel', 'luxury-travel', 'High-end experiences'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Solo Travel', 'solo-travel', 'Independent exploration'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Group Travel', 'group-travel', 'Traveling with others'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Slow Travel', 'slow-travel', 'Long-term stays'),
((SELECT id FROM interest_categories WHERE slug = 'travel-exploration'), 'Travel Photography', 'travel-photography', 'Documenting journeys');

-- ============================================================================
-- VERIFICATION
-- ============================================================================

-- Count interests by category
SELECT
  ic.name AS category,
  COUNT(i.id) AS interest_count
FROM interest_categories ic
LEFT JOIN interests i ON ic.id = i.category_id
GROUP BY ic.name, ic.sort_order
ORDER BY ic.sort_order;

-- Total count
SELECT COUNT(*) AS total_interests FROM interests;
