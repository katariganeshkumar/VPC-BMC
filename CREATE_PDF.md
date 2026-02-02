# How to Create PDF from README-BMC-340B.md

## Method 1: Using Browser (Recommended - Easiest)

1. **Open the HTML file:**
   ```bash
   open README-BMC-340B.html
   ```
   Or double-click `README-BMC-340B.html` in Finder

2. **Print to PDF:**
   - Press `Cmd+P` (Mac) or `Ctrl+P` (Windows)
   - In the print dialog, click "PDF" dropdown
   - Select "Save as PDF"
   - Choose location and filename (e.g., `README-BMC-340B.pdf`)
   - Click "Save"

## Method 2: Using Command Line (macOS)

If you have Chrome/Chromium installed:

```bash
# Install Chrome headless (if needed)
brew install --cask google-chrome

# Convert HTML to PDF
/Applications/Google\ Chrome.app/Contents/MacOS/Google\ Chrome \
  --headless \
  --disable-gpu \
  --print-to-pdf=README-BMC-340B.pdf \
  README-BMC-340B.html
```

## Method 3: Using Python Script

Run the conversion script:

```bash
python3 create_pdf_html.py
```

Then follow Method 1 to convert the HTML to PDF.

## Files Created

- `README-BMC-340B.html` - Formatted HTML file ready for PDF conversion
- `README-BMC-340B.md` - Original markdown file

## Notes

- The HTML file is optimized for printing with proper page breaks
- Tables, code blocks, and diagrams will be preserved
- The PDF will include a table of contents
- All links will be preserved with URLs in parentheses
