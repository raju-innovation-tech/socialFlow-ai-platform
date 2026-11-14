# SocialFlow AI – Unified Metric Definitions & Calculation Standards

## 1. Principles of Truthful Analytics
1. **No Synthetic / Fabricated Data:** Metrics are populated only from official APIs or verified published post performance.
2. **Clear Denominator Identification:** Ratios and rates must clearly specify the denominator used (e.g. impressions vs followers).
3. **Graceful Degradation:** When an official platform API does not support a metric (e.g. Telegram channel views via Bot API, or WhatsApp social reach), the metric is explicitly marked `unavailable`.

---

## 2. Core Metric Formulas

### A. Engagement Rate (ER)
$$\text{Engagement Rate}_{\text{impressions}} = \left( \frac{\text{Reactions} + \text{Comments} + \text{Shares} + \text{Clicks}}{\text{Total Impressions}} \right) \times 100$$
- **Primary Denominator:** `Total Impressions` (where provided by LinkedIn, Facebook, Instagram, YouTube, X).
- **Secondary Denominator (Follower-based):**
  $$\text{Engagement Rate}_{\text{followers}} = \left( \frac{\text{Engagements}}{\text{Follower Count}} \right) \times 100$$
  Used only when impression metrics are restricted by the connected account's API tier.

### B. Follower Growth
$$\text{Absolute Growth} = \text{Followers}_{\text{current}} - \text{Followers}_{\text{baseline}}$$
$$\text{Percentage Growth} = \begin{cases} \left( \frac{\text{Followers}_{\text{current}} - \text{Followers}_{\text{baseline}}}{\text{Followers}_{\text{baseline}}} \right) \times 100 & \text{if Followers}_{\text{baseline}} > 0 \\ 0.0\% & \text{otherwise} \end{cases}$$

### C. Publishing Success Rate
$$\text{Success Rate} = \left( \frac{\text{Published Targets}}{\text{Total Publishing Attempts}} \right) \times 100$$

### D. Period-Over-Period Comparison
$$\% \text{ Change} = \begin{cases} \left( \frac{\text{Value}_{\text{current\_period}} - \text{Value}_{\text{previous\_period}}}{\text{Value}_{\text{previous\_period}}} \right) \times 100 & \text{if Value}_{\text{previous\_period}} > 0 \\ 0.0\% & \text{otherwise} \end{cases}$$

