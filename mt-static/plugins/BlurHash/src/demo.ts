import { decode } from "blurhash";

function isLoaded(img: HTMLImageElement): boolean {
  if (!img.complete) {
    return false;
  }

  if (img.naturalWidth === 0) {
    return false;
  }

  return true;
}

const imgs = document.querySelectorAll("img[data-hash]");
for (let i = 0; i < imgs.length; i++) {
  const img = imgs[i];

  if (isLoaded(img)) {
    continue;
  }

  const width = img.width;
  const height = img.height;
  const pixels = decode(img.dataset.hash, width, height);

  const canvas = document.createElement("canvas");
  canvas.width = width;
  canvas.height = height;
  const ctx = canvas.getContext("2d");
  const imageData = ctx.createImageData(width, height);
  imageData.data.set(pixels);
  ctx.putImageData(imageData, 0, 0);

  img.parentNode.insertBefore(canvas, img);

  img.onload = () => {
    canvas.remove();
  };
}
