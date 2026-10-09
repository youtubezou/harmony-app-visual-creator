import { image } from '@kit.ImageKit';
import { hilog } from '@kit.PerformanceAnalysisKit';

const TAG: string = 'VfxBlurBench';
const DOMAIN: number = 0xB100;

/** Resolution of the locally generated test image. */
const IMG_WIDTH: number = 1080;
const IMG_HEIGHT: number = 1920;

/**
 * Generate the test picture fully locally (no network, no bundled assets):
 * a high-frequency checkerboard mixed with RGB gradients and color bands,
 * so that gaussian blur has plenty of edges to work on at any radius.
 */
function generateTestImage(): Promise<image.PixelMap> {
  const pixelCount: number = IMG_WIDTH * IMG_HEIGHT;
  const pixels: Uint8Array = new Uint8Array(pixelCount * 4);
  const cell: number = 8; // checkerboard cell size in px -> lots of high frequency detail
  for (let y = 0; y < IMG_HEIGHT; y++) {
    const rowOffset: number = y * IMG_WIDTH;
    const gradY: number = Math.floor(y * 255 / IMG_HEIGHT);
    for (let x = 0; x < IMG_WIDTH; x++) {
      const idx: number = (rowOffset + x) * 4;
      const gradX: number = Math.floor(x * 255 / IMG_WIDTH);
      const checker: number = ((Math.floor(x / cell) + Math.floor(y / cell)) % 2 === 0) ? 255 : 0;
      pixels[idx] = checker;                          // R: black/white checkerboard
      pixels[idx + 1] = gradX;                        // G: horizontal gradient
      pixels[idx + 2] = gradY;                        // B: vertical gradient
      pixels[idx + 3] = 255;                          // A: opaque
    }
  }
  const options: image.InitializationOptions = {
    size: { width: IMG_WIDTH, height: IMG_HEIGHT },
    pixelFormat: image.PixelMapFormat.RGBA_8888,
    alphaType: image.AlphaType.ALPHA_TYPE_PREMUL,
    editable: false
  };
  return image.createPixelMap(pixels.buffer as ArrayBuffer, options);
}

@Entry
@Component
struct Index {
  /** Blur radius injected at ability start (0-100, default 20). */
  @StorageLink('blurRadius') blurRadius: number = 20;
  @State testImage: image.PixelMap | undefined = undefined;

  aboutToAppear(): void {
    generateTestImage()
      .then((pixelMap: image.PixelMap) => {
        this.testImage = pixelMap;
        hilog.info(DOMAIN, TAG, `test image generated, blurRadius=${this.blurRadius}`);
      })
      .catch((err: Error) => {
        hilog.error(DOMAIN, TAG, `generateTestImage failed: ${err.message}`);
      });
  }

  build() {
    Stack({ alignContent: Alignment.Top }) {
      // Full-screen locally generated picture with the benchmark blur applied.
      if (this.testImage !== undefined) {
        Image(this.testImage)
          .width('100%')
          .height('100%')
          .objectFit(ImageFit.Cover)
          .blur(this.blurRadius)
      } else {
        Column()
          .width('100%')
          .height('100%')
          .backgroundColor('#101010')
      }
      // Debug overlay so screenshots/logs reveal which radius is being measured.
      Text(`blurRadius = ${this.blurRadius}`)
        .fontSize(28)
        .fontColor('#FFFFFF')
        .fontWeight(FontWeight.Bold)
        .padding(12)
        .backgroundColor('#80000000')
        .borderRadius(8)
        .margin({ top: 64 })
    }
    .width('100%')
    .height('100%')
    .backgroundColor('#000000')
    .expandSafeArea([SafeAreaType.SYSTEM], [SafeEdge.TOP, SafeEdge.BOTTOM])
  }
}
