# Patrick Diamitani Portfolio — Design System

**Version:** 1.0  
**Last Updated:** August 2026  
**Framework:** AWS Well-Architected Framework (Operational Excellence, Security, Reliability, Performance Efficiency, Cost Optimization)

---

## Design Philosophy

**Creator Portfolio Hub.** Three equal-weight content pillars (Leadership Principles, Developer Advocacy, LiveBuildAI) that tell the story of how Patrick thinks, teaches, and builds. Clean, modern, light—built for both humans and machines (accessibility-first, SEO-ready).

**WAF Integration:** Every design decision serves one of the five pillars:
- **Operational Excellence:** Clear information architecture, easy to maintain
- **Security:** HTTPS-only, CSP headers, no third-party JS bloat
- **Reliability:** Static site + CDN (no database), fast failover
- **Performance Efficiency:** Optimize for Lighthouse 95+, lazy-load media
- **Cost Optimization:** S3 + CloudFront, minimal compute, pay-per-request

---

## Color System

### Primary Palette

| Name | Hex | Usage |
|------|-----|-------|
| **Orange (Accent)** | `#FF6B35` | CTAs, highlights, brand accent |
| **Navy (Primary)** | `#0F172A` | Headlines, navigation, authority |
| **White (Canvas)** | `#FFFFFF` | Hero backgrounds, cards |
| **Light Gray (Surface)** | `#F9FAFB` | Section backgrounds, subtle separation |
| **Charcoal (Body Text)** | `#1F2937` | Body copy, primary text |
| **Gray (Supporting)** | `#6B7280` | Captions, metadata, secondary text |
| **Light Border** | `#E5E7EB` | Card borders, subtle dividers |

### CSS Variables

```css
:root {
  --color-primary: #0F172A;
  --color-accent: #FF6B35;
  --color-background: #FFFFFF;
  --color-surface: #F9FAFB;
  --color-text-primary: #1F2937;
  --color-text-secondary: #6B7280;
  --color-border: #E5E7EB;
  --color-success: #10B981;
  --color-error: #EF4444;
}
```

### Accessibility

- **Contrast ratios:** All text meets WCAG AAA (7:1 minimum)
- **No color-only communication:** Icons + labels always paired
- **Dark mode ready:** CSS variables allow inversion without redesign

---

## Typography

### Fonts

| Use | Font | Stack |
|-----|------|-------|
| **Headlines** | Geist Bold | `'Geist', 'Inter', system-ui, sans-serif` |
| **Body** | Inter Regular | `'Inter', system-ui, -apple-system, sans-serif` |
| **Mono** | Courier Prime | `'Courier Prime', monospace` |

**Rationale:** Geist is modern, readable at any size, and designed for the web. Inter is ubiquitous in SaaS (neutral, trusting). Courier Prime for code/technical content.

### Scale

| Level | Size | Weight | Line Height | Usage |
|-------|------|--------|-------------|-------|
| **H1** | 3.5rem / 56px | 800 | 1.1 | Hero title, page headline |
| **H2** | 2rem / 32px | 700 | 1.2 | Section title |
| **H3** | 1.25rem / 20px | 700 | 1.3 | Subsection title |
| **Body Large** | 1.1rem / 18px | 400 | 1.6 | Feature text |
| **Body** | 1rem / 16px | 400 | 1.6 | Default body copy |
| **Body Small** | 0.875rem / 14px | 400 | 1.5 | Metadata, captions |
| **Label** | 0.75rem / 12px | 600 | 1.2 | Tags, badges, nav labels |

**Responsive:** Font sizes scale with viewport. Use `clamp()` for fluid scaling:
```css
h1 { font-size: clamp(2rem, 5vw, 3.5rem); }
```

---

## Spacing & Layout

### Scale (8px Base)

```
8px, 16px, 24px, 32px, 40px, 48px, 56px, 64px, 80px, 96px
```

Use multiples of 8 for all padding, margin, and gaps.

### Max Width

| Context | Max Width |
|---------|-----------|
| Container (main content) | 1200px |
| Narrow (text-heavy) | 800px |
| Full width | None (edge-to-edge) |

### Grid

**Desktop (≥1024px):**
- Three-column layout for section cards
- 24px gap between columns

**Tablet (768px–1023px):**
- Two-column layout
- 20px gap

**Mobile (<768px):**
- Single column, full-width cards
- 16px gap

---

## Components

### Button

```
<a href="#" class="btn btn-primary">Primary CTA →</a>
<a href="#" class="btn btn-secondary">Learn More</a>
```

**Primary (Orange):**
- Background: `--color-accent` (#FF6B35)
- Text: White
- Padding: 14px 28px
- Border radius: 8px
- Hover: Slight lift (transform: translateY(-2px)), shadow increase
- No border

**Secondary (Navy outline):**
- Background: Transparent
- Border: 1px `--color-primary`
- Text: `--color-primary`
- Padding: 14px 28px
- Border radius: 8px
- Hover: Background becomes surface gray

### Card

```html
<article class="card">
  <div class="card-thumbnail"></div>
  <div class="card-content">
    <h3>Title</h3>
    <p>Description</p>
  </div>
</article>
```

**Style:**
- Background: `--color-surface`
- Border: 1px `--color-border`
- Border radius: 16px
- Padding: 20px (thumbnail area has no padding)
- Hover: Slight border color shift to accent, slight elevation (shadow)

### Section

```html
<section class="section">
  <div class="container">
    <h2>Section Title</h2>
    <p>Intro text</p>
    <!-- content -->
  </div>
</section>
```

**Spacing:**
- Padding (vertical): 80px top + bottom
- Background: White or light gray (alternate)
- Border: Optional thin line (1px `--color-border`) between sections

### Video Embed

Responsive iframe with aspect ratio lock:
```html
<div style="position: relative; width: 100%; padding-bottom: 56.25%;">
  <iframe style="position: absolute; top: 0; left: 0; width: 100%; height: 100%; border: none;" 
    src="https://www.youtube.com/embed/VIDEO_ID" 
    allow="accelerometer; autoplay; clipboard-write; encrypted-media; gyroscope; picture-in-picture">
  </iframe>
</div>
```

### Navigation

**Desktop:**
- Sticky top nav, white background, subtle shadow on scroll
- Logo (left), links (center), CTA button (right)
- No hamburger

**Mobile:**
- Same sticky nav
- Logo (left), hamburger menu (right)
- Slide-out drawer navigation

---

## Page Structure

### Home Page (`index.html`)

**Sections (in order):**

1. **Hero**
   - H1: Headline (max 10 words)
   - Subheading: One-liner value prop
   - Two CTAs: "Explore Work" (primary) + "Let's Connect" (secondary)
   - Background: Subtle gradient (white → light gray)
   - No image/video (performance)

2. **Leadership Principles**
   - H2: "Leadership Principles"
   - Grid of 6 cards (3 per row on desktop, 1 on mobile)
   - Each card: principle name, 1-sentence description, link to detail page
   - Background: Light gray section

3. **Developer Advocacy**
   - H2: "Developer Advocacy"
   - Subheading: "15+ video tutorials on automation, AWS, and AI"
   - Grid of 6 featured videos (3 per row)
   - Each: thumbnail (YouTube embed or static), title, meta tags
   - Call-to-action: "Browse all tutorials"

4. **LiveBuildAI**
   - H2: "LiveBuildAI"
   - Subheading: "30+ daily AI news articles + how-to guides"
   - Grid of 6 featured articles (3 per row)
   - Each: category label, title, link
   - Call-to-action: "Read all articles"

5. **Footer**
   - Copyright + "Built with AWS Well-Architected principles"
   - Social links (LinkedIn, GitHub, Twitter)
   - Email signup (optional, if you add newsletter integration)

### Leadership Detail Pages (`/pages/leadership/[principle].html`)

**Each principle page (Learn & Be Curious, Invent & Simplify, etc.):**
- H1: Principle name + AWS definition
- STAR breakdown: Situation, Task, Action, Result (each a section)
- Embedded videos (YouTube iframes)
- Related resources (links, callouts)
- Navigation: Previous/Next principle links (bottom)

### Advocacy & LiveBuildAI (Future)

- Dedicated pages with full grid + filtering/sorting capability
- Video player on click (lightbox or dedicated video page)

---

## Performance & Accessibility

### Lighthouse Targets

- **Performance:** 95+
- **Accessibility:** 100
- **Best Practices:** 95+
- **SEO:** 100

### Optimization Rules

1. **Images:** WebP format, lazy-load below fold, max 1200px width
2. **Videos:** YouTube embeds only (no self-hosted), lazy-load iframes
3. **CSS:** One critical CSS file inline in `<head>`, rest defer-load
4. **JS:** Minimal; no framework (vanilla JS for interactivity only)
5. **Fonts:** System fonts preferred; if custom, 2 weights max (Regular, Bold)
6. **Meta:** Open Graph tags for social sharing, canonical URLs

### Accessibility (WCAG 2.1 AA+)

- Semantic HTML (`<nav>`, `<main>`, `<section>`, `<article>`, `<footer>`)
- `alt` text on all images (or `role="presentation"` if decorative)
- ARIA labels on nav, buttons, form inputs
- Focus visible on interactive elements
- No color-only communication (always pair with icon/text)
- Minimum touch target size: 44px × 44px

---

## AWS Well-Architected Integration

### Operational Excellence

✅ Infrastructure as Code (Terraform)  
✅ Clear naming conventions (resources tagged by environment, owner)  
✅ Monitoring via CloudWatch (page load times, error rates)  
✅ Documentation (this DESIGN.md, deployment guide)

### Security

✅ HTTPS only (CloudFront enforces)  
✅ No server-side code (static site)  
✅ CSP headers (no inline scripts, no third-party trackers)  
✅ S3 bucket policy: public-read only for HTML/CSS/JS/media

### Reliability

✅ Static site (no database, no runtime errors)  
✅ Global CDN (CloudFront multi-region edge caches)  
✅ Automatic failover (Route53 health checks)  
✅ Versioned deployments (CI/CD pipeline with rollback)

### Performance Efficiency

✅ CloudFront caching (aggressive for static assets, smart TTL for HTML)  
✅ Lazy-load media (iframes, images below fold)  
✅ Lighthouse 95+ (monitored post-deploy)  
✅ Regional S3 (us-east-1 for lowest latency with CloudFront)

### Cost Optimization

✅ S3 Standard (no Glacier, no excessive versions)  
✅ CloudFront (pay-per-request, no reserved capacity)  
✅ No compute (Lambda cold starts, EC2, RDS all avoided)  
✅ Route53 (minimal query volume: ~1M queries @ $0.40)

---

## Deployment Architecture

See `ARCHITECTURE.md` for AWS infrastructure details (S3 + CloudFront + Route53 + CI/CD).

---

## Future Enhancements (Not In Scope)

- Dark mode toggle (CSS variable swap in JS)
- Article filtering/search (client-side, no backend)
- Email newsletter signup (third-party form embed)
- Blog with RSS feed (static site generator)
- Analytics (privacy-first; consider Plausible over Google Analytics)

---

## Version History

| Version | Date | Changes |
|---------|------|---------|
| 1.0 | Aug 2026 | Initial design system, WAF integration, AWS architecture |

---

## Sign-Off

**Designer:** Claude (Design Consultant)  
**Product Owner:** Patrick Diamitani  
**Stakeholders:** AWS Solution Architecture team

Approved for implementation: _______________
