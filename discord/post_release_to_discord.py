#!/usr/bin/env python3
"""Post GitHub Release to Discord via webhook"""

import requests
import sys
import os
import json
from datetime import datetime

def get_release_info():
    repo = os.getenv('GITHUB_REPOSITORY')
    server_url = os.getenv('GITHUB_SERVER_URL', 'https://github.com')
    
    tag_name = os.getenv('RELEASE_TAG')
    release_name = os.getenv('RELEASE_NAME')
    release_body = os.getenv('RELEASE_BODY', '')
    release_url = os.getenv('RELEASE_URL')
    
    if not tag_name:
        event_path = os.getenv('GITHUB_EVENT_PATH')
        if event_path and os.path.exists(event_path):
            with open(event_path, 'r') as f:
                event = json.load(f)
                if 'release' in event:
                    tag_name = event['release'].get('tag_name')
                    release_name = event['release'].get('name')
                    release_body = event['release'].get('body', '')
                    release_url = event['release'].get('html_url')
    
    return {
        'repo': repo,
        'server_url': server_url,
        'tag_name': tag_name,
        'release_name': release_name or tag_name,
        'release_body': release_body,
        'release_url': release_url or f"{server_url}/{repo}/releases/tag/{tag_name}"
    }

def get_release_assets():
    repo = os.getenv('GITHUB_REPOSITORY')
    tag_name = os.getenv('RELEASE_TAG')
    github_token = os.getenv('GITHUB_TOKEN')
    
    if not repo or not tag_name:
        return []
    
    api_url = f"https://api.github.com/repos/{repo}/releases/tags/{tag_name}"
    
    headers = {
        'Accept': 'application/vnd.github.v3+json',
    }
    
    if github_token:
        headers['Authorization'] = f'token {github_token}'
    
    try:
        response = requests.get(api_url, headers=headers)
        response.raise_for_status()
        release_data = response.json()
        
        return release_data.get('assets', [])
    except Exception as e:
        print(f"Warning: Could not fetch release assets: {e}")
        return []

def parse_changelog(release_body):
    """Parse changelog and format for Discord with spoilers for mod sections"""
    if not release_body:
        return "No changelog provided."
    
    lines = release_body.strip().split('\n')
    formatted_lines = []
    in_mod_section = False
    current_section = []
    section_title = ""
    
    for line in lines:
        # Skip markdown headers and separators
        if line.startswith('#') and not line.startswith('##'):
            continue
        if line.strip() == '---':
            continue
            
        # Detect mod change sections (Added, Removed, Updated)
        if line.startswith('### ✅ Added'):
            if current_section:
                # Close previous section
                formatted_lines.append(f"||{chr(10).join(current_section)}||")
            section_title = "**✅ Mods Added**"
            current_section = []
            in_mod_section = True
        elif line.startswith('### ❌ Removed'):
            if current_section:
                formatted_lines.append(f"||{chr(10).join(current_section)}||")
            section_title = "**❌ Mods Removed**"
            current_section = []
            in_mod_section = True
        elif line.startswith('### 🔄 Updated'):
            if current_section:
                formatted_lines.append(f"||{chr(10).join(current_section)}||")
            section_title = "**🔄 Mods Updated**"
            current_section = []
            in_mod_section = True
        elif line.startswith('##'):
            # Close any open mod section
            if current_section:
                formatted_lines.append(f"||{chr(10).join(current_section)}||")
                current_section = []
            in_mod_section = False
            # Keep other section headers
            section_name = line.replace('##', '').strip()
            if section_name not in ['Downloads', '📥 Downloads']:
                formatted_lines.append(f"\n**{section_name}**")
        elif in_mod_section:
            # Collect mod items in current section
            if line.strip() and not line.startswith('#'):
                if not current_section:
                    formatted_lines.append(section_title)
                current_section.append(line.strip())
        else:
            # Regular content
            if line.strip() and not line.startswith('#'):
                formatted_lines.append(line.strip())
    
    # Close final section if needed
    if current_section:
        formatted_lines.append(f"||{chr(10).join(current_section)}||")
    
    result = '\n'.join(formatted_lines)
    
    # Truncate if too long
    max_length = 4000
    if len(result) > max_length:
        result = result[:max_length - 50] + "\n\n... (changelog truncated)"
    
    return result

def create_release_embed(release_info, assets):
    changelog = parse_changelog(release_info['release_body'])
    
    embed = {
        "title": f"🎉 {release_info['release_name']}",
        "url": release_info['release_url'],
        "description": changelog,
        "color": 5814783,  # Nice purple color
        "fields": [],
        "timestamp": datetime.utcnow().isoformat()
    }
    
    # Add download links as fields
    if assets:
        mrpack_assets = []
        server_assets = []
        
        for asset in assets:
            name = asset['name']
            url = asset['browser_download_url']
            size = asset['size']
            
            size_mb = size / (1024 * 1024)
            size_str = f"{size_mb:.1f}MB" if size_mb >= 1 else f"{size / 1024:.0f}KB"
            
            name_lower = name.lower()
            if name_lower.endswith('.mrpack'):
                mrpack_assets.append(f"[📦 {name}]({url}) `{size_str}`")
            elif 'server' in name_lower and name_lower.endswith('.zip'):
                server_assets.append(f"[🖥️ {name}]({url}) `{size_str}`")
        
        if mrpack_assets:
            embed["fields"].append({
                "name": "📥 Client Download (Prism/Modrinth Launcher)",
                "value": "\n".join(mrpack_assets),
                "inline": False
            })
        
        if server_assets:
            embed["fields"].append({
                "name": "🖥️ Server Download",
                "value": "\n".join(server_assets),
                "inline": False
            })
    
    embed["footer"] = {
        "text": f"Released by {os.getenv('GITHUB_ACTOR', 'Unknown')} • Click mod sections to expand"
    }
    
    return embed

def send_to_discord_webhook(webhook_url, embed, username=None, avatar_url=None):
    payload = {
        "embeds": [embed]
    }
    
    if username:
        payload["username"] = username
    
    if avatar_url:
        payload["avatar_url"] = avatar_url
    
    try:
        response = requests.post(webhook_url, json=payload)
        response.raise_for_status()
        print(f"Release notification sent successfully!")
        return True
    except requests.exceptions.RequestException as e:
        print(f"Failed to send Discord notification: {e}")
        if hasattr(e, 'response') and e.response is not None:
            print(f"Response: {e.response.text}")
        return False

if __name__ == "__main__":
    print("Gathering release information...")
    release_info = get_release_info()
    
    if not release_info['tag_name']:
        print("Error: Could not determine release tag")
        sys.exit(1)
    
    print(f"Release: {release_info['release_name']} ({release_info['tag_name']})")
    
    print("Fetching release assets...")
    assets = get_release_assets()
    print(f"Found {len(assets)} asset(s)")
    
    print("Creating Discord embed...")
    embed = create_release_embed(release_info, assets)
    webhook_url = os.getenv('DISCORD_WEBHOOK_URL')
    
    if not webhook_url:
        print("Error: DISCORD_WEBHOOK_URL required for webhook mode")
        sys.exit(1)
    
    webhook_username = os.getenv('DISCORD_WEBHOOK_USERNAME', 'GitHub Releases')
    webhook_avatar = os.getenv('DISCORD_WEBHOOK_AVATAR_URL')
    
    print("Sending via Discord webhook...")
    success = send_to_discord_webhook(webhook_url, embed, webhook_username, webhook_avatar)
    
    sys.exit(0 if success else 1)
