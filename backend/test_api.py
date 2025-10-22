#!/usr/bin/env python
"""
Test script for TikTok Analytics API endpoints
"""
import json
import sys
from pathlib import Path

# Add backend to Python path
backend_dir = Path(__file__).parent
sys.path.insert(0, str(backend_dir))

# Setup Django
import os
os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

import django
django.setup()

from posts.models import Post
from posts.serializers import TikTokJSONImportSerializer

def test_import():
    """Test importing sample.json data"""
    print("=" * 60)
    print("Testing TikTok Analytics API")
    print("=" * 60)
    
    # Load sample data
    sample_path = backend_dir.parent / 'data' / 'sample.json'
    
    if not sample_path.exists():
        print(f"❌ Sample file not found: {sample_path}")
        return False
    
    print(f"\n📄 Loading data from: {sample_path}")
    
    with open(sample_path, 'r') as f:
        data = json.load(f)
    
    print(f"✅ Loaded {len(data['posts'])} posts from JSON\n")
    
    # Validate and import
    print("🔍 Validating data...")
    serializer = TikTokJSONImportSerializer(data=data)
    
    if not serializer.is_valid():
        print("❌ Validation failed:")
        print(json.dumps(serializer.errors, indent=2))
        return False
    
    print("✅ Data validation passed\n")
    
    # Import
    print("📥 Importing posts...")
    result = serializer.save()
    
    print(f"""
✅ Import complete!

Statistics:
- Total in file: {result['metadata']['total_posts']}
- Imported: {result['imported']}
- Created: {result['created']}
- Updated: {result['updated']}
- Failed: {result['failed']}
""")
    
    if result.get('errors'):
        print("⚠️  Errors encountered:")
        print(json.dumps(result['errors'], indent=2))
    
    # Query posts
    print("\n" + "=" * 60)
    print("Querying imported posts...")
    print("=" * 60 + "\n")
    
    posts = Post.objects.all()
    print(f"📊 Total posts in database: {posts.count()}\n")
    
    for post in posts[:3]:
        print(f"Post ID: {post.post_id}")
        print(f"  Title: {post.title[:60]}...")
        print(f"  Likes: {post.likes:,}")
        print(f"  Views: {post.views:,}" if post.views else "  Views: N/A")
        print(f"  Date: {post.date}")
        print(f"  Engagement Ratio: {post.engagement_ratio}")
        print()
    
    return True

if __name__ == '__main__':
    try:
        success = test_import()
        sys.exit(0 if success else 1)
    except Exception as e:
        print(f"\n❌ Error: {e}")
        import traceback
        traceback.print_exc()
        sys.exit(1)
