
// antes de todo agrega la libreria "Video Library for Processing 4"
import processing.video.*;

Capture cam;
PImage edgeImg;
float precisionFactor = 1.0f;
int limite = 80;
int maxWidth = 1920;
int maxHeight = 1080;
int camWidth, camHeight;

void settings() {
  // Establece un tamaño temporal para la ventana
  size(640, 480);
}

void setup() {
  String[] cameras = Capture.list();
  
  if (cameras.length == 0) {
    println("No se encontró ninguna cámara.");
    exit();
  } else {
    println("Cámaras disponibles:");
    for (int i = 0; i < cameras.length; i++) {
      println(cameras[i]);
    }
    
    // Inicializa la cámara
    cam = new Capture(this, cameras[0]);
    cam.start();
  }
}

void draw() {
  if (cam.available()) {
    cam.read();
    
    // Obtener el tamaño de la cámara una vez que esté disponible
    if (camWidth == 0 && camHeight == 0) {
      camWidth = cam.width;
      camHeight = cam.height;
      
      // Limitar el tamaño de la cámara a un máximo de 1920x1080
      if (camWidth > maxWidth || camHeight > maxHeight) {
        float aspectRatio = (float)camWidth / (float)camHeight;
        
        if (camWidth > camHeight) {
          camWidth = maxWidth;
          camHeight = (int)(maxWidth / aspectRatio);
        } else {
          camHeight = maxHeight;
          camWidth = (int)(maxHeight * aspectRatio);
        }
      }
      
      // Ajustar el tamaño de la ventana al tamaño de la cámara
      surface.setSize(camWidth, camHeight);
      edgeImg = createImage(camWidth, camHeight, RGB);
    }
    
    edgeDetection(cam);
    image(edgeImg, 0, 0);
    keyPressed();
  }
}

void edgeDetection(PImage img) {
  img.loadPixels();
  edgeImg.loadPixels();
  
  PImage gray = createImage(img.width, img.height, ALPHA);
  PImage blurred = createImage(img.width, img.height, ALPHA);
  PImage gradient = createImage(img.width, img.height, ALPHA);

  // Convertir a escala de grises
  for (int i = 0; i < img.pixels.length; i++) {
    int c = img.pixels[i];
    float r = red(c) * 0.299;
    float g = green(c) * 0.587;
    float b = blue(c) * 0.114;
    float grayValue = r + g + b;
    gray.pixels[i] = color(grayValue);
  }
  
  // Aplicar desenfoque gaussiano
  gray.filter(BLUR, precisionFactor);
  blurred = gray;
  
  // Operador de Sobel para calcular gradiente y dirección
  float[] Gx = {-1, 0, 1, -2, 0, 2, -1, 0, 1};
  float[] Gy = {-1, -2, -1, 0, 0, 0, 1, 2, 1};

  for (int y = 1; y < img.height - 1; y++) {
    for (int x = 1; x < img.width - 1; x++) {
      float sumX = 0;
      float sumY = 0;
      
      // Calcular el gradiente
      for (int i = -1; i <= 1; i++) {
        for (int j = -1; j <= 1; j++) {
          float pixel = brightness(blurred.pixels[(x + i) + (y + j) * img.width]);
          sumX += Gx[(i + 1) + (j + 1) * 3] * pixel;
          sumY += Gy[(i + 1) + (j + 1) * 3] * pixel;
        }
      }
      
      float magnitude = sqrt(sumX * sumX + sumY * sumY);
      gradient.pixels[x + y * img.width] = color(magnitude);
    }
  }
  
  gradient.updatePixels();

  // Supresión no máxima y umbral doble
  for (int y = 1; y < img.height - 1; y++) {
    for (int x = 1; x < img.width - 1; x++) {
      float mag = brightness(gradient.pixels[x + y * img.width]);
      edgeImg.pixels[x + y * img.width] = mag > limite ? color(255) : color(0); // Aplicar un umbral
    }
  }

  edgeImg.updatePixels();
}

void keyPressed() {
  if (keyPressed == true) {
      if (keyCode == UP && precisionFactor < 100) {
        precisionFactor *= 1.01;
        print(precisionFactor);
      } else if (keyCode == DOWN && precisionFactor > 0) {
        precisionFactor /= 1.01;
        if( precisionFactor < 0.1){
          precisionFactor = 0.1;
        }
        print(precisionFactor);
      } else if (keyCode == RIGHT && limite < 250){
        limite += 1;
        print(limite);
      }else if (keyCode == LEFT && limite > 10){
        limite -= 1;
        if( limite < 10){
          limite = 10;
        }
        print(limite);
      }
      print("\n");
  }
}
