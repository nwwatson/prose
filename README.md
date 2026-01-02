# Prose 📝

**A modern newsletter and publishing platform built with Rails 8 and Hotwire**

Prose is a comprehensive newsletter platform designed to compete with services like Substack, offering writers and publishers everything they need to build, grow, and monetize their audience.

## 🌟 Features

### Core Publishing
- **Rich Text Editor**: Powered by Lexxy (Basecamp's Lexical-based editor) for distraction-free writing
- **Post Management**: Full CRUD with draft/scheduled/published workflow
- **Content Organization**: Series, tags, and pinned posts
- **Version Control**: Complete revision history with diff viewing and restoration
- **Templates**: Reusable post templates for consistent content
- **Co-authoring**: Multiple authors per post with attribution

### Subscriber Management
- **Subscriber Lists**: Import, export, and organize subscribers
- **Tagging System**: Organize subscribers with custom tags
- **Email Preferences**: Granular control over subscriber preferences
- **Double Opt-in**: Secure subscription confirmation flow

### Email Delivery
- **Campaign Management**: Rich email campaigns with targeting
- **Analytics**: Open rates, click tracking, and engagement metrics
- **Send Optimization**: ML-powered send time optimization
- **Templates**: Mobile-responsive, dark mode compatible emails
- **Delivery**: Powered by Mailgun with high deliverability

### Community Features
- **Threaded Comments**: Real-time commenting with Turbo Streams
- **Voting System**: Community-driven content ranking
- **Moderation Tools**: Spam detection and content moderation
- **Polls & Surveys**: Interactive reader engagement
- **Discussion Posts**: Dedicated discussion format

### Reader Experience
- **Bookmarks**: Save articles for later reading
- **Reading History**: Track reading progress and resume
- **Highlights**: Text highlighting with personal notes
- **Accessibility**: WCAG 2.1 AA compliant with screen reader support

### Analytics & Intelligence
- **Engagement Scoring**: Subscriber engagement analytics
- **Cohort Analysis**: Retention tracking and insights
- **Growth Metrics**: Comprehensive dashboard and reporting

### Monetization (Stripe Integration)
- **Subscriptions**: Free and paid subscriber tiers
- **Payment Processing**: Secure Stripe integration
- **Revenue Analytics**: Financial reporting and insights

## 🏗️ Architecture

### Tech Stack
- **Backend**: Ruby 3.4.5, Rails 8.1.1
- **Frontend**: Hotwire (Turbo + Stimulus), Tailwind CSS
- **Database**: SQLite with auto-incrementing integer primary keys
- **Background Jobs**: Solid Queue
- **Caching**: Solid Cache
- **Real-time**: Solid Cable (ActionCable)
- **Email**: Mailgun (production), letter_opener (development)
- **Payments**: Stripe
- **File Storage**: Active Storage

### Design Principles
- **Concerns-based Architecture**: Modular, composable functionality
- **Progressive Enhancement**: Works without JavaScript, enhanced with it
- **Performance First**: Optimized for speed and scalability
- **Accessibility**: Built with inclusivity in mind
- **Developer Experience**: Comprehensive test suite and modern tooling

## 🚀 Getting Started

### Prerequisites
- Ruby 3.4.5
- Rails 8.1.1
- SQLite 3
- Node.js (for asset compilation)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/prose.git
   cd prose
   ```

2. **Install dependencies**
   ```bash
   bundle install
   npm install
   ```

3. **Setup database**
   ```bash
   bin/rails db:create
   bin/rails db:migrate
   bin/rails db:seed
   ```

4. **Start the development server**
   ```bash
   bin/dev
   ```

5. **Visit the application**
   Open [http://localhost:3000](http://localhost:3000)

### Environment Configuration

Copy the example environment file and configure your settings:

```bash
cp .env.example .env
```

Required environment variables:
- `MAILGUN_API_KEY` - Mailgun API key for email delivery
- `STRIPE_PUBLISHABLE_KEY` - Stripe public key
- `STRIPE_SECRET_KEY` - Stripe secret key
- `SECRET_KEY_BASE` - Rails secret key base

## 🧪 Testing

### Run the test suite
```bash
bin/rails test
```

### Run system tests
```bash
bin/rails test:system
```

### Check code quality
```bash
bundle exec rubocop
```

### Test coverage
```bash
bundle exec simplecov
```

## 📊 Database Schema

The application uses a comprehensive data model with 36+ tables organized into logical phases:

- **Core**: Publications, Posts, Users, Accounts
- **Content**: Tags, Series, Comments, Versions
- **Subscribers**: Email lists, preferences, segmentation
- **Email**: Campaigns, deliveries, analytics
- **Engagement**: Bookmarks, highlights, reading history
- **Monetization**: Subscriptions, payments via Stripe

See `docs/data_model.md` for complete schema documentation.

## 🏗️ Development Roadmap

The project follows an 8-phase development plan:

1. **Phase 1**: Core Publishing Foundation (6-8 weeks)
2. **Phase 2**: Subscriber Management (4-5 weeks)
3. **Phase 3**: Email Delivery Enhancement (4-5 weeks)
4. **Phase 4**: Comments & Community (5-6 weeks)
5. **Phase 5**: Reader Experience (3-4 weeks)
6. **Phase 6**: Analytics & Intelligence (2-3 weeks)
7. **Phase 7**: Community Features (2-3 weeks)
8. **Phase 8**: SEO & Security (3-4 weeks)

**Total Estimated Duration**: 6-9 months

See `docs/roadmap.md` for detailed sprint breakdown and `docs/development_prompts.md` for implementation prompts.

## 📖 Documentation

- `docs/overview.md` - Project overview and feature list
- `docs/data_model.md` - Complete database schema
- `docs/design_guide.md` - Rails development patterns and guidelines
- `docs/roadmap.md` - Development roadmap and technical considerations
- `docs/development_prompts.md` - Claude Code implementation prompts

## 🤝 Contributing

### Development Workflow

1. **Feature Branches**: Create feature branches following the naming convention
2. **Tests Required**: All new code must include comprehensive tests
3. **Code Quality**: RuboCop must pass with zero offenses
4. **Pull Requests**: Submit PRs with detailed descriptions
5. **Review Process**: Code review required before merging

### Code Standards

- Follow Rails conventions and best practices
- Use concerns for shared functionality
- Write comprehensive tests (models, controllers, system)
- Ensure accessibility compliance
- Document public APIs

## 🎯 Goals

Prose aims to provide:

1. **Best-in-class Writing Experience**: Distraction-free editor with powerful features
2. **Audience Growth**: Tools to grow and engage subscribers
3. **Revenue Generation**: Built-in monetization without complexity
4. **Community Building**: Foster engaged reader communities
5. **Performance**: Fast, reliable platform that scales
6. **Accessibility**: Inclusive design for all users

---

**Built with ❤️ using Rails 8, Hotwire, and modern web standards.**
