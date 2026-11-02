import glob
import zipfile
from xml.etree import ElementTree as ET
import re

for path in [
    r'C:\Users\Terano\Downloads\Week 5 - Find Anomaly.pptx',
    r'C:\Users\Terano\Downloads\Week 7 - OutlierDetection ML.ppt',
]:
    print('=' * 80)
    print('FILE:', path)
    try:
        if zipfile.is_zipfile(path):
            with zipfile.ZipFile(path, 'r') as z:
                slides = [f for f in z.namelist() if re.match(r'ppt/slides/slide\d+\.xml$', f)]
                slides.sort(key=lambda x: int(re.search(r'slide(\d+)\.xml', x).group(1)))
                for s in slides:
                    root = ET.fromstring(z.read(s))
                    texts = [t.text.strip() for t in root.iter() if t.tag.endswith('}t') and t.text and t.text.strip()]
                    print(f'--- {s} ---')
                    print(' | '.join(texts))
        else:
            with open(path, 'rb') as f:
                data = f.read()
            # Extract ASCII and UTF-16LE strings from .ppt binary
            ascii_strs = re.findall(b'[A-Za-z0-9 ,.;:?!()\\-/\'"+%=<>]{6,}', data)
            utf16_strs = re.findall(b'(?:[A-Za-z0-9 ,.;:?!()\\-/\'"+%=<>]\x00){6,}', data)
            print('--- Binary PPT text chunks ---')
            seen = set()
            for s in utf16_strs:
                txt = s.decode('utf-16le', errors='ignore').strip()
                if len(txt) > 5 and txt not in seen:
                    seen.add(txt)
                    print('[U16]', txt)
            for s in ascii_strs:
                txt = s.decode('latin1', errors='ignore').strip()
                if len(txt) > 8 and not any(k in txt for k in ['Microsoft', 'PowerPoint', 'Times New Roman', 'Arial', 'Calibri', ' Master', 'Document']) and txt not in seen:
                    seen.add(txt)
                    print('[ASC]', txt)
    except Exception as e:
        print('Error reading', path, e)
