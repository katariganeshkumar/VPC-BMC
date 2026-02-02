#!/usr/bin/env python3
"""
Create a well-formatted HTML file from README-BMC-340B.md that can be printed to PDF
"""

import markdown
import os
import re

def convert_markdown_to_html(markdown_file, html_file):
    """Convert markdown to styled HTML"""
    
    print(f"Reading {markdown_file}...")
    with open(markdown_file, 'r', encoding='utf-8') as f:
        md_content = f.read()
    
    print("Converting markdown to HTML...")
    # Convert markdown to HTML with extensions
    html_content = markdown.markdown(
        md_content,
        extensions=['toc', 'fenced_code', 'tables', 'codehilite', 'nl2br']
    )
    
    # Create full HTML document with professional styling
    html_document = f"""<!DOCTYPE html>
<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>BMC 340B Cloud Infrastructure Documentation</title>
    <style>
        @media print {{
            @page {{
                size: A4;
                margin: 2cm;
            }}
            body {{
                font-size: 11pt;
            }}
            h1 {{
                page-break-before: always;
                page-break-after: avoid;
            }}
            h2, h3 {{
                page-break-after: avoid;
            }}
            pre, blockquote {{
                page-break-inside: avoid;
            }}
        }}
        
        * {{
            margin: 0;
            padding: 0;
            box-sizing: border-box;
        }}
        
        body {{
            font-family: -apple-system, BlinkMacSystemFont, 'Segoe UI', Roboto, 'Helvetica Neue', Arial, sans-serif;
            line-height: 1.6;
            color: #333;
            max-width: 1200px;
            margin: 0 auto;
            padding: 20px;
            background-color: #fff;
        }}
        
        h1 {{
            color: #2c3e50;
            border-bottom: 4px solid #3498db;
            padding-bottom: 15px;
            margin-bottom: 30px;
            font-size: 2.5em;
            page-break-before: auto;
        }}
        
        h2 {{
            color: #34495e;
            border-bottom: 2px solid #95a5a6;
            padding-bottom: 10px;
            margin-top: 40px;
            margin-bottom: 20px;
            font-size: 1.8em;
            page-break-before: auto;
        }}
        
        h3 {{
            color: #555;
            margin-top: 25px;
            margin-bottom: 15px;
            font-size: 1.4em;
        }}
        
        h4 {{
            color: #666;
            margin-top: 20px;
            margin-bottom: 10px;
            font-size: 1.2em;
        }}
        
        p {{
            margin-bottom: 15px;
            text-align: justify;
        }}
        
        code {{
            background-color: #f4f4f4;
            padding: 3px 8px;
            border-radius: 4px;
            font-family: 'Courier New', 'Monaco', 'Menlo', monospace;
            font-size: 0.9em;
            color: #e83e8c;
        }}
        
        pre {{
            background-color: #f8f9fa;
            padding: 20px;
            border-radius: 6px;
            overflow-x: auto;
            border-left: 4px solid #3498db;
            margin: 20px 0;
            page-break-inside: avoid;
        }}
        
        pre code {{
            background-color: transparent;
            padding: 0;
            color: #333;
            font-size: 0.85em;
        }}
        
        table {{
            border-collapse: collapse;
            width: 100%;
            margin: 25px 0;
            box-shadow: 0 2px 4px rgba(0,0,0,0.1);
            page-break-inside: avoid;
        }}
        
        th, td {{
            border: 1px solid #dee2e6;
            padding: 12px 15px;
            text-align: left;
        }}
        
        th {{
            background-color: #3498db;
            color: white;
            font-weight: 600;
        }}
        
        tr:nth-child(even) {{
            background-color: #f8f9fa;
        }}
        
        tr:hover {{
            background-color: #e9ecef;
        }}
        
        blockquote {{
            border-left: 4px solid #3498db;
            margin: 25px 0;
            padding-left: 25px;
            color: #666;
            font-style: italic;
            background-color: #f8f9fa;
            padding: 15px 25px;
            border-radius: 4px;
        }}
        
        a {{
            color: #3498db;
            text-decoration: none;
        }}
        
        a:hover {{
            text-decoration: underline;
        }}
        
        ul, ol {{
            margin-left: 30px;
            margin-bottom: 20px;
        }}
        
        li {{
            margin-bottom: 8px;
        }}
        
        .toc {{
            background-color: #f8f9fa;
            padding: 25px;
            margin: 30px 0;
            border-radius: 8px;
            border: 1px solid #dee2e6;
        }}
        
        .toc h2 {{
            border-bottom: none;
            margin-top: 0;
        }}
        
        .toc ul {{
            list-style-type: none;
            margin-left: 0;
        }}
        
        .toc li {{
            margin-bottom: 10px;
        }}
        
        .toc a {{
            color: #495057;
            font-weight: 500;
        }}
        
        hr {{
            border: none;
            border-top: 2px solid #dee2e6;
            margin: 40px 0;
        }}
        
        .header-info {{
            background-color: #e8f4f8;
            padding: 20px;
            border-radius: 8px;
            margin-bottom: 30px;
            border-left: 4px solid #3498db;
        }}
        
        @media print {{
            .no-print {{
                display: none;
            }}
            a[href^="http"]:after {{
                content: " (" attr(href) ")";
                font-size: 0.8em;
                color: #666;
            }}
        }}
        
        .print-instructions {{
            background-color: #fff3cd;
            border: 1px solid #ffc107;
            padding: 15px;
            border-radius: 6px;
            margin-bottom: 20px;
            font-size: 0.9em;
        }}
    </style>
</head>
<body>
    <div class="print-instructions no-print">
        <strong>📄 To create PDF:</strong> Press <kbd>Cmd+P</kbd> (Mac) or <kbd>Ctrl+P</kbd> (Windows), 
        select "Save as PDF" as the destination, and click Save.
    </div>
    
    {html_content}
    
    <hr>
    <footer style="text-align: center; color: #666; margin-top: 40px; padding-top: 20px; border-top: 1px solid #dee2e6;">
        <p>BMC 340B Cloud Infrastructure Documentation</p>
        <p style="font-size: 0.9em;">Generated from README-BMC-340B.md</p>
    </footer>
</body>
</html>"""
    
    print(f"Writing HTML to {html_file}...")
    with open(html_file, 'w', encoding='utf-8') as f:
        f.write(html_document)
    
    print(f"✅ Successfully created {html_file}")
    print(f"\n📄 To create PDF:")
    print(f"   1. Open {html_file} in your web browser")
    print(f"   2. Press Cmd+P (Mac) or Ctrl+P (Windows)")
    print(f"   3. Select 'Save as PDF'")
    print(f"   4. Click Save")
    
    return html_file

if __name__ == '__main__':
    markdown_file = 'README-BMC-340B.md'
    html_file = 'README-BMC-340B.html'
    
    if not os.path.exists(markdown_file):
        print(f"Error: {markdown_file} not found!")
        exit(1)
    
    convert_markdown_to_html(markdown_file, html_file)
