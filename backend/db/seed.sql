-- Seed script for local development and testing
-- This script creates test users, audio items, comments, reactions, etc.
-- Run with: docker exec -i amunx-postgres-1 psql -U postgres -d amunx < db/seed.sql

-- Clear existing test data (optional - uncomment if you want to reset)
-- TRUNCATE TABLE audio_items, comments, likes, saves, user_follows, feed_events CASCADE;
-- TRUNCATE TABLE users CASCADE;

-- Insert test users
INSERT INTO users (id, handle, email, display_name, avatar, plan, created_at) VALUES
  ('10000000-0000-0000-0000-000000000001', 'testuser1', 'test1@example.com', 'Test User 1', 'https://i.pravatar.cc/150?img=1', 'free', now() - interval '30 days'),
  ('10000000-0000-0000-0000-000000000002', 'testuser2', 'test2@example.com', 'Test User 2', 'https://i.pravatar.cc/150?img=2', 'pro', now() - interval '20 days'),
  ('10000000-0000-0000-0000-000000000003', 'testuser3', 'test3@example.com', 'Test User 3', 'https://i.pravatar.cc/150?img=3', 'free', now() - interval '10 days'),
  ('10000000-0000-0000-0000-000000000004', 'testuser4', 'test4@example.com', 'Test User 4', 'https://i.pravatar.cc/150?img=4', 'free', now() - interval '5 days'),
  ('10000000-0000-0000-0000-000000000005', 'testuser5', 'test5@example.com', 'Test User 5', 'https://i.pravatar.cc/150?img=5', 'pro', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

-- Insert test profiles
INSERT INTO profiles (user_id, bio, settings, created_at) VALUES
  ('10000000-0000-0000-0000-000000000001', 'Tech enthusiast and podcaster', '{}'::jsonb, now()),
  ('10000000-0000-0000-0000-000000000002', 'Music producer and audio engineer', '{}'::jsonb, now()),
  ('10000000-0000-0000-0000-000000000003', 'Content creator and storyteller', '{}'::jsonb, now()),
  ('10000000-0000-0000-0000-000000000004', 'Developer and tech blogger', '{}'::jsonb, now()),
  ('10000000-0000-0000-0000-000000000005', 'Artist and creative director', '{}'::jsonb, now())
ON CONFLICT (user_id) DO NOTHING;

-- Insert test topics
INSERT INTO topics (id, slug, title, description, owner_id, is_public, created_at) VALUES
  ('20000000-0000-0000-0000-000000000001', 'tech', 'Technology', 'Discussions about technology and innovation', '10000000-0000-0000-0000-000000000001', true, now() - interval '25 days'),
  ('20000000-0000-0000-0000-000000000002', 'music', 'Music', 'Music production and audio engineering', '10000000-0000-0000-0000-000000000002', true, now() - interval '20 days'),
  ('20000000-0000-0000-0000-000000000003', 'design', 'Design', 'Design and creativity discussions', '10000000-0000-0000-0000-000000000005', true, now() - interval '15 days')
ON CONFLICT (id) DO NOTHING;

-- Insert test audio items (episodes) - 25 total for scrolling
INSERT INTO audio_items (id, owner_id, kind, visibility, title, description, duration_sec, s3_key, audio_url, tags, created_at) VALUES
  ('30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000001', 'podcast_episode', 'public', 'Introduction to Flutter Development', 'Learn the basics of Flutter development', 1800, 'test/ep1.mp3', 'https://example.com/audio/ep1.mp3', ARRAY['flutter', 'mobile', 'development'], now() - interval '7 days'),
  ('30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', 'podcast_episode', 'public', 'Advanced State Management', 'Deep dive into state management patterns', 2400, 'test/ep2.mp3', 'https://example.com/audio/ep2.mp3', ARRAY['flutter', 'state-management', 'riverpod'], now() - interval '5 days'),
  ('30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', 'podcast_episode', 'public', 'Music Production Tips', 'Professional tips for music production', 3600, 'test/ep3.mp3', 'https://example.com/audio/ep3.mp3', ARRAY['music', 'production', 'audio'], now() - interval '3 days'),
  ('30000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000002', 'podcast_episode', 'public', 'Audio Mixing Techniques', 'Advanced techniques for audio mixing', 2700, 'test/ep4.mp3', 'https://example.com/audio/ep4.mp3', ARRAY['audio', 'mixing', 'mastering'], now() - interval '2 days'),
  ('30000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000003', 'podcast_episode', 'public', 'Storytelling in Digital Age', 'Exploring storytelling in the digital age', 2100, 'test/ep5.mp3', 'https://example.com/audio/ep5.mp3', ARRAY['storytelling', 'content', 'digital'], now() - interval '1 day'),
  ('30000000-0000-0000-0000-000000000006', '10000000-0000-0000-0000-000000000004', 'podcast_episode', 'public', 'Building REST APIs with Go', 'Building robust REST APIs using Go', 3300, 'test/ep6.mp3', 'https://example.com/audio/ep6.mp3', ARRAY['go', 'api', 'backend'], now() - interval '6 hours'),
  ('30000000-0000-0000-0000-000000000007', '10000000-0000-0000-0000-000000000005', 'podcast_episode', 'public', 'Creative Design Process', 'Understanding the creative design process', 1500, 'test/ep7.mp3', 'https://example.com/audio/ep7.mp3', ARRAY['design', 'creativity', 'process'], now() - interval '3 hours'),
  ('30000000-0000-0000-0000-000000000008', '10000000-0000-0000-0000-000000000001', 'micro', 'public', 'Short: Quick Tips for Developers', 'Quick tips for developers', 120, 'test/short1.mp3', 'https://example.com/audio/short1.mp3', ARRAY['tips', 'development'], now() - interval '1 hour'),
  ('30000000-0000-0000-0000-000000000009', '10000000-0000-0000-0000-000000000002', 'micro', 'public', 'Short: Music Theory Basics', 'Music theory basics explained', 90, 'test/short2.mp3', 'https://example.com/audio/short2.mp3', ARRAY['music', 'theory'], now() - interval '30 minutes'),
  ('30000000-0000-0000-0000-000000000010', '10000000-0000-0000-0000-000000000003', 'podcast_episode', 'public', 'Productivity Hacks for Creators', 'Best productivity tips for content creators', 1950, 'test/ep10.mp3', 'https://example.com/audio/ep10.mp3', ARRAY['productivity', 'tips', 'creator'], now() - interval '8 days'),
  ('30000000-0000-0000-0000-000000000011', '10000000-0000-0000-0000-000000000004', 'micro', 'public', 'Short: Docker Tips', 'Quick Docker containerization tips', 150, 'test/short3.mp3', 'https://example.com/audio/short3.mp3', ARRAY['docker', 'devops'], now() - interval '4 hours'),
  ('30000000-0000-0000-0000-000000000012', '10000000-0000-0000-0000-000000000005', 'podcast_episode', 'public', 'UI/UX Design Principles', 'Fundamental principles of great UI/UX design', 2800, 'test/ep12.mp3', 'https://example.com/audio/ep12.mp3', ARRAY['ui', 'ux', 'design'], now() - interval '9 days'),
  ('30000000-0000-0000-0000-000000000013', '10000000-0000-0000-0000-000000000001', 'podcast_episode', 'public', 'Microservices Architecture', 'Building scalable microservices', 3200, 'test/ep13.mp3', 'https://example.com/audio/ep13.mp3', ARRAY['microservices', 'architecture', 'backend'], now() - interval '11 days'),
  ('30000000-0000-0000-0000-000000000014', '10000000-0000-0000-0000-000000000002', 'micro', 'public', 'Short: Vocal Recording Tips', 'Quick tips for recording vocals', 110, 'test/short4.mp3', 'https://example.com/audio/short4.mp3', ARRAY['vocal', 'recording'], now() - interval '2 hours'),
  ('30000000-0000-0000-0000-000000000015', '10000000-0000-0000-0000-000000000003', 'podcast_episode', 'public', 'Content Marketing Strategies', 'Effective content marketing for creators', 2600, 'test/ep15.mp3', 'https://example.com/audio/ep15.mp3', ARRAY['marketing', 'content', 'strategy'], now() - interval '12 days'),
  ('30000000-0000-0000-0000-000000000016', '10000000-0000-0000-0000-000000000004', 'podcast_episode', 'public', 'Database Optimization', 'Optimizing PostgreSQL databases', 2900, 'test/ep16.mp3', 'https://example.com/audio/ep16.mp3', ARRAY['database', 'postgresql', 'performance'], now() - interval '13 days'),
  ('30000000-0000-0000-0000-000000000017', '10000000-0000-0000-0000-000000000005', 'micro', 'public', 'Short: Color Theory', 'Quick color theory lesson', 95, 'test/short5.mp3', 'https://example.com/audio/short5.mp3', ARRAY['color', 'design'], now() - interval '5 hours'),
  ('30000000-0000-0000-0000-000000000018', '10000000-0000-0000-0000-000000000001', 'podcast_episode', 'public', 'AI in Mobile Development', 'Integrating AI into mobile apps', 2350, 'test/ep18.mp3', 'https://example.com/audio/ep18.mp3', ARRAY['ai', 'mobile', 'ml'], now() - interval '14 days'),
  ('30000000-0000-0000-0000-000000000019', '10000000-0000-0000-0000-000000000002', 'podcast_episode', 'public', 'Electronic Music Production', 'Creating electronic music from scratch', 3100, 'test/ep19.mp3', 'https://example.com/audio/ep19.mp3', ARRAY['electronic', 'music', 'synth'], now() - interval '15 days'),
  ('30000000-0000-0000-0000-000000000020', '10000000-0000-0000-0000-000000000003', 'micro', 'public', 'Short: Public Speaking Tips', 'Quick public speaking advice', 130, 'test/short6.mp3', 'https://example.com/audio/short6.mp3', ARRAY['speaking', 'tips'], now() - interval '7 hours'),
  ('30000000-0000-0000-0000-000000000021', '10000000-0000-0000-0000-000000000004', 'podcast_episode', 'public', 'Cloud Architecture Patterns', 'Modern cloud architecture patterns', 2750, 'test/ep21.mp3', 'https://example.com/audio/ep21.mp3', ARRAY['cloud', 'architecture', 'aws'], now() - interval '16 days'),
  ('30000000-0000-0000-0000-000000000022', '10000000-0000-0000-0000-000000000005', 'podcast_episode', 'public', 'Typography in Web Design', 'Choosing and using typography effectively', 1850, 'test/ep22.mp3', 'https://example.com/audio/ep22.mp3', ARRAY['typography', 'web', 'design'], now() - interval '17 days'),
  ('30000000-0000-0000-0000-000000000023', '10000000-0000-0000-0000-000000000001', 'micro', 'public', 'Short: Git Workflow', 'Efficient Git workflow tips', 105, 'test/short7.mp3', 'https://example.com/audio/short7.mp3', ARRAY['git', 'workflow'], now() - interval '8 hours'),
  ('30000000-0000-0000-0000-000000000024', '10000000-0000-0000-0000-000000000002', 'podcast_episode', 'public', 'Podcast Equipment Guide', 'Essential equipment for podcasting', 2200, 'test/ep24.mp3', 'https://example.com/audio/ep24.mp3', ARRAY['podcast', 'equipment', 'guide'], now() - interval '18 days'),
  ('30000000-0000-0000-0000-000000000025', '10000000-0000-0000-0000-000000000003', 'podcast_episode', 'public', 'Building Personal Brand', 'Creating and growing your personal brand', 2450, 'test/ep25.mp3', 'https://example.com/audio/ep25.mp3', ARRAY['branding', 'personal', 'growth'], now() - interval '19 days')
ON CONFLICT (id) DO NOTHING;

-- Insert test summaries
INSERT INTO summaries (audio_id, preview_sentence, tldr, keywords, mood, chapters) VALUES
  ('30000000-0000-0000-0000-000000000001', 'Learn the basics of Flutter development and how to build your first mobile app.', 'Learn the basics of Flutter development and how to build your first mobile app. This episode covers widgets, state management, and building your first app.', ARRAY['flutter', 'mobile', 'development', 'dart'], '{"energy": 0.8, "positivity": 0.9}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000002', 'Deep dive into state management patterns in Flutter applications.', 'Deep dive into state management patterns in Flutter applications. We explore Riverpod, Provider, and other state management solutions.', ARRAY['flutter', 'state-management', 'riverpod', 'architecture'], '{"energy": 0.7, "positivity": 0.8}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000003', 'Professional tips for music production and audio engineering.', 'Professional tips for music production and audio engineering. Learn from industry experts about mixing, mastering, and production workflows.', ARRAY['music', 'production', 'audio', 'engineering'], '{"energy": 0.9, "positivity": 0.85}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000004', 'Advanced techniques for audio mixing and mastering.', 'Advanced techniques for audio mixing and mastering. Discover professional workflows and tools for creating polished audio content.', ARRAY['audio', 'mixing', 'mastering', 'production'], '{"energy": 0.75, "positivity": 0.8}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000005', 'Exploring storytelling in the digital age and how to engage audiences.', 'Exploring storytelling in the digital age and how to engage audiences. Learn how to create compelling narratives that resonate with your listeners.', ARRAY['storytelling', 'content', 'digital', 'engagement'], '{"energy": 0.8, "positivity": 0.9}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000006', 'Building robust REST APIs using Go programming language.', 'Building robust REST APIs using Go programming language. We cover routing, middleware, database integration, and best practices.', ARRAY['go', 'api', 'backend', 'rest'], '{"energy": 0.7, "positivity": 0.75}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000007', 'Understanding the creative design process from concept to execution.', 'Understanding the creative design process from concept to execution. Explore how designers approach projects from ideation to final delivery.', ARRAY['design', 'creativity', 'process', 'visual'], '{"energy": 0.85, "positivity": 0.9}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000010', 'Best productivity tips for content creators and digital workers.', 'Discover productivity hacks that will help you create more content in less time while maintaining quality.', ARRAY['productivity', 'tips', 'creator', 'workflow'], '{"energy": 0.85, "positivity": 0.9}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000012', 'Fundamental principles of great UI/UX design.', 'Master the fundamental principles of UI/UX design. Learn about user research, wireframing, prototyping, and testing.', ARRAY['ui', 'ux', 'design', 'principles'], '{"energy": 0.8, "positivity": 0.85}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000013', 'Building scalable microservices with modern tools.', 'Learn how to build scalable microservices using Go, Docker, and Kubernetes. Best practices for distributed systems.', ARRAY['microservices', 'architecture', 'backend', 'scalability'], '{"energy": 0.75, "positivity": 0.8}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000015', 'Effective content marketing strategies for digital creators.', 'Learn content marketing strategies that work. From SEO to social media, discover how to reach your audience.', ARRAY['marketing', 'content', 'strategy', 'seo'], '{"energy": 0.8, "positivity": 0.85}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000016', 'Optimizing PostgreSQL databases for high performance.', 'Deep dive into PostgreSQL optimization. Indexes, query planning, and performance tuning for production systems.', ARRAY['database', 'postgresql', 'performance', 'optimization'], '{"energy": 0.7, "positivity": 0.75}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000018', 'Integrating AI into mobile applications.', 'Explore how to integrate machine learning and AI into your mobile apps. Practical examples with Flutter and TensorFlow.', ARRAY['ai', 'mobile', 'ml', 'tensorflow'], '{"energy": 0.85, "positivity": 0.9}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000019', 'Creating electronic music from scratch.', 'Learn electronic music production. Synthesis, sampling, arrangement, and mixing for electronic genres.', ARRAY['electronic', 'music', 'synth', 'production'], '{"energy": 0.9, "positivity": 0.85}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000021', 'Modern cloud architecture patterns for scalable applications.', 'Explore modern cloud architecture patterns. Serverless, containers, and managed services on AWS and GCP.', ARRAY['cloud', 'architecture', 'aws', 'serverless'], '{"energy": 0.75, "positivity": 0.8}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000022', 'Choosing and using typography effectively in web design.', 'Master typography in web design. Font selection, pairing, hierarchy, and responsive typography.', ARRAY['typography', 'web', 'design', 'fonts'], '{"energy": 0.8, "positivity": 0.85}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000024', 'Essential equipment for starting your podcast.', 'Complete guide to podcast equipment. Microphones, interfaces, headphones, and software for professional podcasting.', ARRAY['podcast', 'equipment', 'guide', 'audio'], '{"energy": 0.8, "positivity": 0.85}'::jsonb, '[]'::jsonb),
  ('30000000-0000-0000-0000-000000000025', 'Creating and growing your personal brand online.', 'Build a strong personal brand. Strategy, content creation, networking, and monetization for creators.', ARRAY['branding', 'personal', 'growth', 'creator'], '{"energy": 0.85, "positivity": 0.9}'::jsonb, '[]'::jsonb)
ON CONFLICT (audio_id) DO NOTHING;

-- Insert test comments
INSERT INTO comments (id, audio_id, author_id, text, created_at) VALUES
  ('40000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', 'Great episode! Very informative.', now() - interval '6 days'),
  ('40000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000003', 'Thanks for sharing this!', now() - interval '5 days'),
  ('40000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000004', 'This helped me understand state management better.', now() - interval '4 days'),
  ('40000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', 'Amazing production quality!', now() - interval '2 days'),
  ('40000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000005', 'Can you do a follow-up on mastering?', now() - interval '1 day')
ON CONFLICT (id) DO NOTHING;

-- Insert test likes
INSERT INTO likes (user_id, audio_id, created_at) VALUES
  ('10000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', now() - interval '6 days'),
  ('10000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', now() - interval '5 days'),
  ('10000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000001', now() - interval '4 days'),
  ('10000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000001', now() - interval '3 days'),
  ('10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', now() - interval '2 days'),
  ('10000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000003', now() - interval '1 day'),
  ('10000000-0000-0000-0000-000000000004', '30000000-0000-0000-0000-000000000003', now() - interval '12 hours'),
  ('10000000-0000-0000-0000-000000000005', '30000000-0000-0000-0000-000000000002', now() - interval '4 days')
ON CONFLICT (user_id, audio_id) DO NOTHING;

-- Insert test user follows
INSERT INTO user_follows (follower_id, followee_id, created_at) VALUES
  ('10000000-0000-0000-0000-000000000002', '10000000-0000-0000-0000-000000000001', now() - interval '25 days'),
  ('10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000001', now() - interval '20 days'),
  ('10000000-0000-0000-0000-000000000004', '10000000-0000-0000-0000-000000000001', now() - interval '15 days'),
  ('10000000-0000-0000-0000-000000000001', '10000000-0000-0000-0000-000000000002', now() - interval '18 days'),
  ('10000000-0000-0000-0000-000000000003', '10000000-0000-0000-0000-000000000002', now() - interval '12 days'),
  ('10000000-0000-0000-0000-000000000005', '10000000-0000-0000-0000-000000000002', now() - interval '8 days')
ON CONFLICT (follower_id, followee_id) DO NOTHING;

-- Insert test feed events
INSERT INTO feed_events (user_id, audio_id, event, created_at) VALUES
  ('10000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000001', 'play', now() - interval '7 days'),
  ('10000000-0000-0000-0000-000000000003', '30000000-0000-0000-0000-000000000001', 'play', now() - interval '6 days'),
  ('10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000002', 'play', now() - interval '5 days'),
  ('10000000-0000-0000-0000-000000000002', '30000000-0000-0000-0000-000000000003', 'play', now() - interval '3 days'),
  ('10000000-0000-0000-0000-000000000001', '30000000-0000-0000-0000-000000000003', 'complete', now() - interval '2 days')
ON CONFLICT DO NOTHING;

-- Insert test topic follows
INSERT INTO follows (user_id, topic_id, created_at) VALUES
  ('10000000-0000-0000-0000-000000000002', '20000000-0000-0000-0000-000000000001', now() - interval '20 days'),
  ('10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000001', now() - interval '15 days'),
  ('10000000-0000-0000-0000-000000000004', '20000000-0000-0000-0000-000000000001', now() - interval '10 days'),
  ('10000000-0000-0000-0000-000000000001', '20000000-0000-0000-0000-000000000002', now() - interval '18 days'),
  ('10000000-0000-0000-0000-000000000003', '20000000-0000-0000-0000-000000000002', now() - interval '12 days')
ON CONFLICT (user_id, topic_id) DO NOTHING;
