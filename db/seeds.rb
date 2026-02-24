# frozen_string_literal: true

# Idempotent seed file — safe to re-run. Clears existing data first.
# Usage: bin/rails db:seed

puts "Seeding database..."

# ---------------------------------------------------------------------------
# Site settings (singleton)
# ---------------------------------------------------------------------------
SiteSetting.find_or_create_by!(id: 1) do |s|
  s.site_name = "Prose"
  s.site_description = "A thoughtfully crafted publication"
end
puts "  Site settings configured"

# ---------------------------------------------------------------------------
# Clear existing data (order matters for FK constraints)
# ---------------------------------------------------------------------------
Comment.delete_all
Love.delete_all
PostView.delete_all
PostTag.delete_all
Post.delete_all
Session.delete_all
User.delete_all
Subscriber.delete_all
Identity.delete_all
Tag.delete_all
Category.delete_all

# ---------------------------------------------------------------------------
# Staff users
# ---------------------------------------------------------------------------
admin = User.create!(
  email: "admin@example.com",
  display_name: "Alice Thornton",
  password: "P@ssw0rd!Strong1",
  password_confirmation: "P@ssw0rd!Strong1",
  role: :admin
)

writer = User.create!(
  email: "writer@example.com",
  display_name: "Ben Carroway",
  password: "P@ssw0rd!Strong1",
  password_confirmation: "P@ssw0rd!Strong1",
  role: :writer
)

admin.identity.update!(handle: "alice_thornton", bio: "Editor-in-chief and lead author. Writing about technology, culture, and the future.", website_url: "https://alicethornton.com", twitter_handle: "alicethornton")
writer.identity.update!(handle: "ben_carroway", bio: "Staff writer covering science, philosophy, and everyday observations.")

staff_users = [ admin, writer ]
puts "  Created #{staff_users.size} staff users"

# ---------------------------------------------------------------------------
# Categories
# ---------------------------------------------------------------------------
category_data = [
  { name: "Technology", description: "Software, hardware, and the digital world" },
  { name: "Design", description: "Visual design, UX, and creative thinking" },
  { name: "Business", description: "Strategy, leadership, and entrepreneurship" },
  { name: "Culture", description: "Society, art, and the human experience" },
  { name: "Science", description: "Research, discovery, and the natural world" },
  { name: "Travel", description: "Destinations, adventures, and wanderlust" },
  { name: "Health", description: "Wellness, fitness, and mental health" },
  { name: "Education", description: "Learning, teaching, and personal growth" }
]

categories = category_data.map { |attrs| Category.create!(attrs) }
puts "  Created #{categories.size} categories"

# ---------------------------------------------------------------------------
# Tags
# ---------------------------------------------------------------------------
tag_names = %w[
  ruby rails javascript typescript python react
  ai machine-learning devops docker kubernetes
  css tailwind design-systems accessibility
  startups remote-work productivity career
  open-source security performance testing
  databases sql api rest graphql
  mobile ios android flutter
  writing creativity mindfulness photography
]

tags = tag_names.map { |name| Tag.create!(name: name) }
puts "  Created #{tags.size} tags"

# ---------------------------------------------------------------------------
# Subscribers (100)
# ---------------------------------------------------------------------------
first_names = %w[
  Emma Liam Olivia Noah Ava Elijah Sophia James Isabella William
  Mia Benjamin Charlotte Lucas Amelia Henry Harper Ethan Evelyn Alexander
  Abigail Daniel Emily Matthew Ella Sebastian Avery Jack Scarlett Owen
  Madison Aiden Luna Michael Chloe Jackson Penelope Samuel Layla David
  Riley Wyatt Zoey Carter Nora Luke Grace Gabriel Hannah Jayden
]

last_names = %w[
  Smith Johnson Williams Brown Jones Garcia Miller Davis Rodriguez Martinez
  Hernandez Lopez Gonzalez Wilson Anderson Thomas Taylor Moore Jackson Martin
  Lee Perez Thompson White Harris Sanchez Clark Ramirez Lewis Robinson Walker
  Young Allen King Wright Scott Torres Nguyen Hill Flores Green Adams Nelson
  Baker Hall Rivera Campbell Mitchell Carter Roberts Gomez Phillips Evans
]

subscriber_identities = []
subscribers = 100.times.map do |i|
  first = first_names[i % first_names.size]
  last = last_names[i % last_names.size]
  handle = "#{first.downcase}#{last.downcase}#{i + 1}"
  email = "#{handle}@example.com"
  confirmed_at = i < 90 ? rand(1..180).days.ago : nil

  subscriber = Subscriber.create!(email: email, confirmed_at: confirmed_at)
  subscriber.identity.update!(handle: handle)
  subscriber_identities << subscriber.identity
  subscriber
end
puts "  Created #{subscribers.size} subscribers (#{subscribers.count(&:confirmed?)} confirmed)"

# ---------------------------------------------------------------------------
# Post content helpers
# ---------------------------------------------------------------------------
TOPIC_TITLES = [
  "The Future of %{subject} in a Connected World",
  "Why %{subject} Matters More Than Ever",
  "A Practical Guide to %{subject}",
  "Rethinking %{subject} for the Modern Era",
  "Lessons Learned from Building with %{subject}",
  "%{subject}: What Nobody Tells You",
  "How %{subject} Changed My Perspective",
  "The Unexpected Benefits of %{subject}",
  "Getting Started with %{subject}: A Beginner's Journey",
  "Beyond the Hype: The Real Story of %{subject}",
  "5 Myths About %{subject} Debunked",
  "%{subject} in Practice: A Case Study",
  "The Art and Science of %{subject}",
  "Why I Stopped Worrying and Learned to Love %{subject}",
  "A Deep Dive into %{subject}",
  "The Hidden Complexity of %{subject}",
  "%{subject} Best Practices for 2026",
  "Scaling %{subject} Without Losing Your Mind",
  "What %{subject} Can Teach Us About Life",
  "The Evolution of %{subject}"
].freeze

SUBJECTS = [
  "Remote Work", "Ruby on Rails", "Artificial Intelligence", "Design Systems",
  "Open Source", "Developer Experience", "Sustainable Tech", "API Design",
  "Team Culture", "Side Projects", "Code Reviews", "Technical Writing",
  "Database Optimization", "Frontend Performance", "Cloud Architecture",
  "Product Thinking", "Test-Driven Development", "Pair Programming",
  "System Design", "Container Orchestration", "Web Accessibility",
  "Mobile Development", "Data Privacy", "Mentorship", "Creative Coding"
].freeze

SUBTITLES = [
  "Practical insights from the trenches",
  "What the research actually says",
  "A framework for thinking clearly",
  "Lessons from a decade of experience",
  "Why conventional wisdom is wrong",
  "An opinionated guide for practitioners",
  "Bridging theory and practice",
  "Notes from a recovering perfectionist",
  nil, nil, nil
].freeze

PARAGRAPHS = [
  "The landscape has shifted dramatically over the past few years. What was once considered cutting-edge is now table stakes, and the innovations happening at the margins are reshaping how we think about the fundamentals. It is worth pausing to consider where we have been and where we are headed.",
  "When I first encountered this topic, I was skeptical. The promises seemed too good to be true, and the existing solutions felt adequate. But after spending months exploring the space, I have come to appreciate the nuance and depth that lies beneath the surface.",
  "There is a common misconception that you need to choose between simplicity and power. In my experience, the best solutions find a way to deliver both. The key is understanding the trade-offs and making intentional decisions about where to invest complexity.",
  "One of the most underrated skills in our field is the ability to communicate clearly. Technical excellence matters, but it is multiplied when combined with the ability to explain, persuade, and collaborate. This is something I have had to learn the hard way.",
  "The tooling ecosystem has matured significantly. Where we once had to build everything from scratch, we now have robust, well-maintained options for nearly every common problem. The challenge has shifted from building tools to choosing the right ones.",
  "I have been thinking a lot about sustainability lately — not just environmental sustainability, but the sustainability of our practices, our teams, and our codebases. The decisions we make today compound over time, for better or worse.",
  "Collaboration is the secret ingredient that separates good teams from great ones. It is not just about code reviews and stand-ups; it is about creating an environment where people feel safe to experiment, fail, and learn from each other.",
  "Performance optimization is often treated as an afterthought, something you deal with when things get slow. But the most effective teams I have worked with treat performance as a feature, building it into their process from day one.",
  "Testing is one of those topics where everyone agrees it is important, but opinions diverge wildly on how to do it well. After years of experimentation, I have arrived at a philosophy that prioritizes confidence over coverage.",
  "The best code I have ever written is code I deleted. There is a certain elegance in removing unnecessary complexity, and it takes discipline to resist the urge to add more when less will do.",
  "Documentation is a form of empathy. When you write good docs, you are thinking about your future self, your teammates, and the strangers who will inherit your work. It is one of the highest-leverage activities a developer can invest in.",
  "Debugging is an underappreciated art. The ability to systematically narrow down a problem, form hypotheses, and validate them is a skill that transfers far beyond software. It is essentially the scientific method applied to code.",
  "Architecture decisions are the ones that are hardest to reverse. They deserve more thought, more discussion, and more documentation than we typically give them. A decision record can save weeks of confusion down the line.",
  "The gap between junior and senior developers is not about syntax or frameworks. It is about judgment — knowing when to build versus buy, when to optimize versus ship, and when to say no to a feature request.",
  "Mentorship has been the most rewarding part of my career. There is something deeply satisfying about helping someone see a problem from a new angle, or watching them have that moment where everything clicks into place.",
  "I used to think that working harder was the path to better results. Now I understand that working smarter — being intentional about where you direct your energy — is far more effective. Rest is not the opposite of productivity; it is a prerequisite.",
  "The community around open source is one of the most remarkable things about our industry. People volunteering their time and expertise to build tools that benefit everyone is a powerful reminder of what collaboration can achieve.",
  "Security is not a feature you bolt on at the end. It is a mindset that should inform every decision, from how you handle user data to how you structure your deployment pipeline. The cost of getting it wrong is simply too high.",
  "Accessibility is not just about compliance; it is about building products that work for everyone. When you design with accessibility in mind, you often end up with a better experience for all users, not just those with disabilities.",
  "The most important skill I have developed is the ability to ask good questions. The right question at the right time can save days of work, uncover hidden assumptions, and open up possibilities that no one had considered."
]

COMMENT_BODIES = [
  "Great article! This really resonated with me.",
  "I have been thinking about this topic a lot lately. Thanks for putting it into words.",
  "Interesting perspective. I had not considered it from that angle before.",
  "This is exactly what I needed to read today. Bookmarked for future reference.",
  "I mostly agree, but I think there is more nuance to the second point.",
  "Fantastic write-up. The section on trade-offs was particularly insightful.",
  "I have had a similar experience. It is reassuring to know I am not alone.",
  "Could you elaborate on the third point? I would love to hear more about that.",
  "This changed how I think about the problem. Thank you for sharing.",
  "Well said. I am going to share this with my team.",
  "I respectfully disagree with some of this, but I appreciate the thoughtful argument.",
  "The practical examples really helped me understand the concept. More of this please!",
  "I have been doing this wrong for years. Time to rethink my approach.",
  "Love the honesty in this piece. More authors should be this transparent.",
  "This is a topic that does not get enough attention. Glad someone is writing about it.",
  "Solid advice. I implemented some of these ideas and saw immediate results.",
  "The analogy in paragraph three was perfect. It made everything click.",
  "I have been in this industry for 15 years and I still learned something new here.",
  "This should be required reading for anyone starting out in the field.",
  "Thoughtful and well-researched. I appreciate the balanced perspective.",
  "I tried this approach last quarter and it worked surprisingly well.",
  "You articulated something I have felt but could never quite express. Thank you.",
  "The section on common pitfalls saved me from making a costly mistake.",
  "I would add that team size also plays a significant role in this equation.",
  "Curious if you have seen this work at scale. Our team of 50+ has different challenges.",
  "This pairs well with the article you wrote last month. Great follow-up.",
  "My favorite part was the honest assessment of what did not work. Very refreshing.",
  "Sharing this in our engineering Slack channel right now.",
  "Simple, clear, and actionable. This is what good technical writing looks like.",
  "The before-and-after comparison really drove the point home."
]

REPLY_BODIES = [
  "Totally agree with this. Well said!",
  "Good point — I had not thought of it that way.",
  "This has been my experience too.",
  "Thanks for adding this perspective!",
  "Interesting take. I will have to think about that more.",
  "Yes! This is exactly what I was trying to say.",
  "Great follow-up point.",
  "I had the same question. Glad someone asked.",
  "This is a really useful addition to the discussion.",
  "Seconded. This matches what I have seen as well."
]

# ---------------------------------------------------------------------------
# Posts (55)
# ---------------------------------------------------------------------------
used_titles = Set.new
posts = []

55.times do |i|
  subject = SUBJECTS[i % SUBJECTS.size]
  template = TOPIC_TITLES[i % TOPIC_TITLES.size]
  title = format(template, subject: subject)

  # Ensure unique titles
  if used_titles.include?(title)
    title = "#{title} (Part #{(i / TOPIC_TITLES.size) + 1})"
  end
  used_titles << title

  author = staff_users.sample
  category = categories.sample
  subtitle = SUBTITLES.sample
  published_at = rand(1..365).days.ago

  # Build 4-8 paragraphs of content
  num_paragraphs = rand(4..8)
  body_paragraphs = PARAGRAPHS.sample(num_paragraphs).map { |p| "<p>#{p}</p>" }
  body_paragraphs.insert(rand(1..2), "<h2>The Core Idea</h2>")
  body_paragraphs.insert(rand(3..body_paragraphs.size - 1), "<h2>Putting It Into Practice</h2>")
  content_html = body_paragraphs.join("\n\n")

  post = Post.create!(
    title: title,
    subtitle: subtitle,
    user: author,
    category: category,
    status: :published,
    published_at: published_at,
    featured: i < 5,
    content: content_html
  )

  # Assign 1-4 random tags
  post.tags = tags.sample(rand(1..4))

  posts << post
end
puts "  Created #{posts.size} posts"

# ---------------------------------------------------------------------------
# Comments (minimum 3 per post, random up to 12)
# ---------------------------------------------------------------------------
all_identities = subscriber_identities + staff_users.map(&:identity)
confirmed_identities = subscribers.select(&:confirmed?).map(&:identity) + staff_users.map(&:identity)
total_comments = 0

posts.each do |post|
  num_top_level = rand(3..10)
  top_level_comments = []

  num_top_level.times do
    identity = confirmed_identities.sample
    created = post.published_at + rand(1..72).hours

    comment = Comment.create!(
      post: post,
      identity: identity,
      body: COMMENT_BODIES.sample,
      approved: [ true, true, true, true, false ].sample, # 80% approved
      created_at: created,
      updated_at: created
    )
    top_level_comments << comment
    total_comments += 1
  end

  # Add 0-3 replies to random top-level comments
  rand(0..3).times do
    parent = top_level_comments.sample
    identity = confirmed_identities.sample
    created = parent.created_at + rand(1..48).hours

    Comment.create!(
      post: post,
      identity: identity,
      body: REPLY_BODIES.sample,
      parent_comment: parent,
      approved: true,
      created_at: created,
      updated_at: created
    )
    total_comments += 1
  end
end
puts "  Created #{total_comments} comments"

# ---------------------------------------------------------------------------
# Loves (random subset of subscribers love random posts)
# ---------------------------------------------------------------------------
total_loves = 0

confirmed_identities.each do |identity|
  loved_posts = posts.sample(rand(0..15))
  loved_posts.each do |post|
    Love.create!(post: post, identity: identity)
    total_loves += 1
  end
end

# Reset counter caches
posts.each do |post|
  Post.reset_counters(post.id, :loves)
end
puts "  Created #{total_loves} loves"

# ---------------------------------------------------------------------------
# Post views (simulate traffic)
# ---------------------------------------------------------------------------
total_views = 0
sources = %w[direct google twitter linkedin rss email]
user_agents = [
  "Mozilla/5.0 (Macintosh; Intel Mac OS X 10_15_7)",
  "Mozilla/5.0 (Windows NT 10.0; Win64; x64)",
  "Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X)",
  "Mozilla/5.0 (Linux; Android 14)"
]

posts.each do |post|
  rand(5..50).times do
    created = post.published_at + rand(1..168).hours
    PostView.create!(
      post: post,
      ip_hash: SecureRandom.hex(16),
      source: sources.sample,
      user_agent: user_agents.sample,
      referrer: [ nil, "https://google.com", "https://twitter.com", "https://news.ycombinator.com" ].sample,
      created_at: created,
      updated_at: created
    )
    total_views += 1
  end
end
puts "  Created #{total_views} post views"

puts "Done!"
