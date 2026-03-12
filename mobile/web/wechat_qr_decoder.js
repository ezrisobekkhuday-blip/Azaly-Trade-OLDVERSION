(function () {
  function loadImage(source) {
    return new Promise(function (resolve, reject) {
      var image = new Image();
      image.onload = function () {
        resolve(image);
      };
      image.onerror = function () {
        reject(new Error('Failed to load QR image.'));
      };
      image.src = source;
    });
  }

  function extractText(result) {
    if (!result) {
      return '';
    }

    if (typeof result === 'string') {
      return result.trim();
    }

    if (typeof result.rawValue === 'string' && result.rawValue.trim()) {
      return result.rawValue.trim();
    }

    if (typeof result.text === 'string' && result.text.trim()) {
      return result.text.trim();
    }

    if (typeof result.getText === 'function') {
      var text = result.getText();
      if (text) {
        return String(text).trim();
      }
    }

    return '';
  }

  async function decodeWithBarcodeDetector(image) {
    if (typeof window.BarcodeDetector === 'undefined') {
      return '';
    }

    var detector = new window.BarcodeDetector({ formats: ['qr_code'] });
    var barcodes = await detector.detect(image);
    if (!Array.isArray(barcodes)) {
      return '';
    }

    for (var i = 0; i < barcodes.length; i += 1) {
      var value = extractText(barcodes[i]);
      if (value) {
        return value;
      }
    }

    return '';
  }

  async function decodeWithZxing(source, image) {
    if (!window.ZXing || !window.ZXing.BrowserQRCodeReader) {
      throw new Error('ZXing QR reader is unavailable.');
    }

    var reader = new window.ZXing.BrowserQRCodeReader();
    try {
      if (typeof reader.decodeFromImageElement === 'function') {
        var imageResult = await reader.decodeFromImageElement(image);
        var elementText = extractText(imageResult);
        if (elementText) {
          return elementText;
        }
      }

      if (typeof reader.decodeFromImageUrl === 'function') {
        var urlResult = await reader.decodeFromImageUrl(source);
        var urlText = extractText(urlResult);
        if (urlText) {
          return urlText;
        }
      }
    } finally {
      if (typeof reader.reset === 'function') {
        reader.reset();
      }
    }

    return '';
  }

  window.azalyDecodeQrFromDataUrl = async function (source) {
    if (!source) {
      return '';
    }

    var image = await loadImage(source);

    try {
      var detectorText = await decodeWithBarcodeDetector(image);
      if (detectorText) {
        return detectorText;
      }
    } catch (_) {
      // Fall back to ZXing below.
    }

    var zxingText = await decodeWithZxing(source, image);
    if (zxingText) {
      return zxingText;
    }

    throw new Error('QR code was not detected.');
  };
})();
