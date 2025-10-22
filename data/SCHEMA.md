# TikTok Analytics JSON Schema Documentation

## Overview

This document defines the expected JSON structure for TikTok export data used by the TikTok Analytics application.

---

## Schema Version

**Current Version:** `1.0.0`

---

## Root Structure

```json
{
  "metadata": { ... },
  "posts": [ ... ]
}
```

### Top-Level Fields

| Field      | Type   | Required | Description                       |
| ---------- | ------ | -------- | --------------------------------- |
| `metadata` | Object | ✅ Yes   | Information about the data export |
| `posts`    | Array  | ✅ Yes   | Array of TikTok post objects      |

---

## Metadata Object

Information about the export itself.

### Fields

| Field         | Type    | Required | Description                | Format/Constraints                  |
| ------------- | ------- | -------- | -------------------------- | ----------------------------------- |
| `export_date` | String  | ✅ Yes   | When the data was exported | ISO 8601 datetime                   |
| `version`     | String  | ✅ Yes   | Schema version             | Semantic versioning (e.g., "1.0.0") |
| `total_posts` | Integer | ✅ Yes   | Number of posts in export  | Minimum: 0                          |

### Example

```json
{
  "export_date": "2025-10-22T10:30:00Z",
  "version": "1.0.0",
  "total_posts": 150
}
```

---

## Post Object

Represents a single TikTok post.

### Required Fields

| Field        | Type    | Description              | Format/Constraints         |
| ------------ | ------- | ------------------------ | -------------------------- |
| `id`         | String  | Unique post identifier   | Numeric string (19 digits) |
| `title`      | String  | Post caption/description | Max 2,200 characters       |
| `likes`      | Integer | Number of likes          | Minimum: 0                 |
| `date`       | String  | Post creation date       | ISO 8601 datetime          |
| `cover_url`  | String  | Cover image URL          | Valid URL                  |
| `video_link` | String  | TikTok video URL         | Valid TikTok URL           |

### Optional Fields

| Field        | Type          | Description               | Format/Constraints |
| ------------ | ------------- | ------------------------- | ------------------ |
| `views`      | Integer       | Number of views           | Minimum: 0         |
| `comments`   | Integer       | Number of comments        | Minimum: 0         |
| `shares`     | Integer       | Number of shares          | Minimum: 0         |
| `duration`   | Integer       | Video duration in seconds | 1-600 seconds      |
| `hashtags`   | Array[String] | Hashtags used in post     | Array of strings   |
| `is_private` | Boolean       | Whether post is private   | Default: false     |
| `is_pinned`  | Boolean       | Whether post is pinned    | Default: false     |

### Example

```json
{
  "id": "7298765432109876543",
  "title": "Just tried this amazing recipe! 🍕 #cooking #foodie",
  "likes": 15420,
  "date": "2025-09-15T14:23:00Z",
  "cover_url": "https://p16-sign-sg.tiktokcdn.com/example-cover.jpg",
  "video_link": "https://www.tiktok.com/@username/video/7298765432109876543",
  "views": 234567,
  "comments": 892,
  "shares": 1234,
  "duration": 45,
  "hashtags": ["#cooking", "#foodie", "#homemade"],
  "is_private": false,
  "is_pinned": true
}
```

---

## Field Specifications

### ID Format

**Pattern:** `^[0-9]+$`

TikTok post IDs are typically 19-digit numeric strings.

**Example:** `"7298765432109876543"`

### Date Format

**Format:** ISO 8601 with timezone

**Examples:**

- `"2025-10-22T10:30:00Z"` (UTC)
- `"2025-10-22T10:30:00-04:00"` (with timezone offset)

### URL Formats

**Cover URL:** Any valid HTTP/HTTPS URL

**Video Link Pattern:** `^https?://(www\.)?(tiktok\.com|vm\.tiktok\.com)/.+`

**Valid Examples:**

- `https://www.tiktok.com/@username/video/1234567890`
- `https://vm.tiktok.com/ZMhxyz123/`

### Title Constraints

- **Maximum Length:** 2,200 characters
- **Supports:** Unicode characters, emojis, hashtags
- **Empty String:** Allowed (but not recommended)

### Hashtags Format

Array of strings, with or without the `#` prefix.

**Examples:**

```json
["#cooking", "#foodie"]
["cooking", "foodie"]
```

---

## Validation Rules

### Data Integrity

1. **Unique IDs:** Each post must have a unique `id` value
2. **Date Order:** Posts can be in any order (sorting handled by application)
3. **Non-negative Metrics:** `likes`, `views`, `comments`, `shares` must be ≥ 0
4. **Valid URLs:** All URLs must be well-formed and accessible

### Business Logic

1. **Engagement Ratio:** `likes` should generally be ≤ `views` (if both present)
2. **Duration:** Video duration should match TikTok's limits (typically 3s - 10min)
3. **Hashtags:** Recommended but not required for analytics

---

## Sample Files

### Files in this Directory

1. **`schema.json`** — JSON Schema definition (for programmatic validation)
2. **`sample.json`** — Complete example with 3 posts
3. **`SCHEMA.md`** — This documentation file

### Using the Sample

To test your import process:

```bash
# Copy sample to your data file
cp data/sample.json data/tiktok_export.json

# Update backend/.env
TIKTOK_JSON_IMPORT_PATH=../data/tiktok_export.json
```

---

## Schema Evolution

### Version History

- **1.0.0** (2025-10-22) — Initial schema definition

### Future Enhancements

Planned optional fields for future versions:

- `location` — Geographic location of post
- `music` — Background music/sound information
- `effects` — Video effects used
- `collaborators` — Tagged users
- `device` — Device used for recording

---

## Validation Tools

### Python (Django Backend)

```python
import json
import jsonschema

# Load schema
with open('data/schema.json') as f:
    schema = json.load(f)

# Validate data
with open('data/tiktok_export.json') as f:
    data = json.load(f)
    jsonschema.validate(data, schema)
```

### Online Validators

- [JSONSchema Validator](https://www.jsonschemavalidator.net/)
- [JSON Lint](https://jsonlint.com/)

---

## Error Handling

Common validation errors and solutions:

| Error                  | Cause                   | Solution                           |
| ---------------------- | ----------------------- | ---------------------------------- |
| Missing required field | Field omitted from post | Add all required fields            |
| Invalid date format    | Date not in ISO 8601    | Use format: `YYYY-MM-DDTHH:MM:SSZ` |
| Invalid URL            | Malformed URL           | Ensure valid HTTP/HTTPS URL        |
| Negative metric        | Likes/views < 0         | Set to 0 or correct value          |
| Invalid ID format      | Non-numeric ID          | Use numeric string                 |

---

## Best Practices

### Data Export

1. **Always include metadata** with export timestamp
2. **Sort posts** chronologically (newest first recommended)
3. **Include optional fields** when available for richer analytics
4. **Validate before import** using the provided schema

### Data Privacy

1. **Keep exports in `data/` folder** (gitignored)
2. **Don't commit real data** to version control
3. **Use sample data** for testing and documentation
4. **Sanitize data** if sharing for debugging

---

## Support

For questions or issues with the schema:

1. Check this documentation first
2. Validate your JSON against `schema.json`
3. Compare with `sample.json` example
4. Review ROADMAP.md for implementation status

---

**Last Updated:** October 22, 2025  
**Schema Version:** 1.0.0
