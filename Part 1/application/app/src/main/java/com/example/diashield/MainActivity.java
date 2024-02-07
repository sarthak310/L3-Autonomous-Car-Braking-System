package com.example.diashield;

import androidx.annotation.NonNull;
import androidx.appcompat.app.AppCompatActivity;
import androidx.core.app.ActivityCompat;

import android.Manifest;
import android.content.Context;
import android.content.Intent;
import android.content.pm.PackageManager;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;
import android.graphics.Bitmap;
import android.graphics.Color;
import android.graphics.SurfaceTexture;
import android.hardware.Sensor;
import android.hardware.SensorEvent;
import android.hardware.SensorEventListener;
import android.hardware.SensorManager;
import android.hardware.camera2.CameraAccessException;
import android.hardware.camera2.CameraCaptureSession;
import android.hardware.camera2.CameraCharacteristics;
import android.hardware.camera2.CameraDevice;
import android.hardware.camera2.CameraManager;
import android.hardware.camera2.CameraMetadata;
import android.hardware.camera2.CaptureRequest;
import android.hardware.camera2.params.StreamConfigurationMap;
import android.os.Bundle;
import android.os.Handler;
import android.util.Size;
import android.view.Surface;
import android.view.TextureView;
import android.view.View;
import android.widget.Button;
import android.widget.TextView;
import android.widget.Toast;

import com.example.diashield.Utils.DatabaseHandler;

import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

public class MainActivity extends AppCompatActivity implements SensorEventListener{

    private TextureView textureView;
    private CaptureRequest.Builder captureBuilder;
    private CameraDevice cameraDevice;
    private CameraCaptureSession captureSession;
    private Handler backgroundHandler;
    private Size viewSize;

    private int movingAverage;
    private int movingAveragePrevious;
    private int movingAveragePreviousPrevious;
    private double heartRate;
    private List<Long> peakBeats = new ArrayList<>();
    private int noOfFrames = 0;
    Button buttonMeasureHeartRate;
    TextView heartRateMeasureText;

    protected DatabaseHandler db;

    List<Float> accelerometerValueX = new ArrayList<>();
    List<Float> accelerometerValueY = new ArrayList<>();
    List<Float> accelerometerValueZ = new ArrayList<>();
    private double RespiratoryRate;
    private SensorManager manageAccelerometer;
    private Sensor accelerometerSensor;
    Button buttonMeasureRespiratoryRate;
    TextView textViewMeasureRespiratoryRate1;

    Button symptomsButton;
    int symptomId;
    public static final String EXTRA_MESSAGE = "com.example.diashield.MESSAGE";

    SQLiteDatabase database;
    Button buttonUploadSigns;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_main);

        db = new DatabaseHandler(this);
        db.openDatabase();

        textureView = findViewById(R.id.textureViewCameraView);
        textureView.setSurfaceTextureListener(surfaceTextureListener);

        heartRateMeasureText = (TextView)findViewById(R.id.textViewMeasureHeartRate);
        buttonMeasureHeartRate = (Button)findViewById(R.id.buttonMeasureHeartRate);
        buttonMeasureHeartRate.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                heartRateMeasureText.setText("Heart Rate: Measuring...");
                onCamera();
                Handler delayHandler = new Handler();
                delayHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        cameraDevice.close();
                        MeasureHeartRate();
                        heartRateMeasureText.setText("Heart Rate: " + String.format("%.4f", heartRate));
                    }
                }, 45000);
            }
        });


        manageAccelerometer = (SensorManager) getSystemService(Context.SENSOR_SERVICE);
        accelerometerSensor = manageAccelerometer.getDefaultSensor(Sensor.TYPE_ACCELEROMETER);
        manageAccelerometer.registerListener((SensorEventListener) this, accelerometerSensor, SensorManager.SENSOR_DELAY_NORMAL);

        textViewMeasureRespiratoryRate1 = (TextView)findViewById(R.id.textViewMeasureRespiratoryRate);
        buttonMeasureRespiratoryRate = (Button)findViewById(R.id.buttonMeasureRespiratoryRate);
        buttonMeasureRespiratoryRate.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                textViewMeasureRespiratoryRate1.setText("Respiratory Rate: Measuring...");
                Handler delayHandler = new Handler();
                delayHandler.postDelayed(new Runnable() {
                    @Override
                    public void run() {
                        MeasureRespiratoryRate();
                        textViewMeasureRespiratoryRate1.setText("Respiratory Rate: " + String.format("%.1f", RespiratoryRate));
                    }
                }, 45000);
            }
        });

        buttonUploadSigns = (Button)findViewById(R.id.buttonUploadSigns);
        buttonUploadSigns.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                db.uploadSigns(heartRate, RespiratoryRate);
                Toast.makeText(MainActivity.this, "Signs Uploaded Successfully", Toast.LENGTH_LONG).show();
                heartRateMeasureText.setText("Heart Rate: 0.0");
                textViewMeasureRespiratoryRate1.setText("Respiratory Rate: 0.0");
            }
        });

        symptomsButton = (Button)findViewById(R.id.symptomsButton);
        symptomsButton.setOnClickListener(new View.OnClickListener() {
            @Override
            public void onClick(View v) {
                ClickSymptoms();
            }
        });

    }

    private TextureView.SurfaceTextureListener surfaceTextureListener = new TextureView.SurfaceTextureListener() {
        @Override
        public void onSurfaceTextureAvailable(@NonNull SurfaceTexture surface, int width, int height) {

        }

        @Override
        public void onSurfaceTextureSizeChanged(@NonNull SurfaceTexture surface, int width, int height) {

        }

        @Override
        public boolean onSurfaceTextureDestroyed(@NonNull SurfaceTexture surface) {
            return false;
        }

        @Override
        public void onSurfaceTextureUpdated(@NonNull SurfaceTexture surface) {
            Bitmap bitmapImage = textureView.getBitmap();
            int redPixelsSum = 0;
            int[] imagePixels = new int[bitmapImage.getHeight() * bitmapImage.getWidth() / 4];
            bitmapImage.getPixels(imagePixels, 0, bitmapImage.getWidth()/2,bitmapImage.getWidth()/4, bitmapImage.getHeight()/4, bitmapImage.getWidth()/2, bitmapImage.getHeight()/2);
            for(int i=0;i<imagePixels.length;i++){
                redPixelsSum = redPixelsSum + Color.red(imagePixels[i]);
            }
            if(noOfFrames > 50){
                if(noOfFrames > 150){
                    movingAverage = (movingAverage * 100 + redPixelsSum) / 101;
                    if((movingAverage < movingAveragePrevious) && (movingAveragePrevious > movingAveragePreviousPrevious)){
                        peakBeats.add(System.currentTimeMillis());
                    }
                }
                else{
                    movingAverage = (movingAverage * (noOfFrames - 50) + redPixelsSum) / (noOfFrames - 49);
                }
            }
            else{
                movingAverage = redPixelsSum;
            }

            noOfFrames++;
            movingAveragePreviousPrevious = movingAveragePrevious;
            movingAveragePrevious = movingAverage;
        }
    };

    private CameraDevice.StateCallback cameraStateCallback = new CameraDevice.StateCallback() {
        @Override
        public void onOpened(@NonNull CameraDevice camera) {
            cameraDevice = camera;
            cameraView();
        }

        @Override
        public void onDisconnected(@NonNull CameraDevice camera) {
            camera.close();
            cameraDevice = null;
        }

        @Override
        public void onError(@NonNull CameraDevice camera, int error) {
            camera.close();
            cameraDevice = null;
        }
    };

    private void cameraView() {
        try {
            SurfaceTexture surfaceTexture = textureView.getSurfaceTexture();
            assert surfaceTexture != null;
            surfaceTexture.setDefaultBufferSize(viewSize.getWidth(), viewSize.getHeight());
            Surface surface = new Surface(surfaceTexture);
            captureBuilder = cameraDevice.createCaptureRequest(CameraDevice.TEMPLATE_PREVIEW);
            captureBuilder.addTarget(surface);

            cameraDevice.createCaptureSession(Arrays.asList(surface), new CameraCaptureSession.StateCallback() {
                @Override
                public void onConfigured(@NonNull CameraCaptureSession cameraCaptureSession) {
                    if(cameraDevice != null) {
                        try {
                            captureSession = cameraCaptureSession;
                            captureBuilder.set(CaptureRequest.CONTROL_MODE, CameraMetadata.CONTROL_MODE_AUTO);
                            captureBuilder.set(CaptureRequest.FLASH_MODE, CameraMetadata.FLASH_MODE_TORCH);
                            captureSession.setRepeatingRequest(captureBuilder.build(), null, backgroundHandler);
                        } catch (CameraAccessException e) {
                            e.printStackTrace();
                        }
                    }
                }

                @Override
                public void onConfigureFailed(@NonNull CameraCaptureSession session) {

                }
            }, null);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    private void onCamera(){
        CameraManager cameraManager = (CameraManager) getSystemService(Context.CAMERA_SERVICE);
        try {
            String cameraId = cameraManager.getCameraIdList()[0];

            CameraCharacteristics cameraCharacteristics = cameraManager.getCameraCharacteristics(cameraId);
            StreamConfigurationMap configMap = cameraCharacteristics.get(CameraCharacteristics.SCALER_STREAM_CONFIGURATION_MAP);
            viewSize = configMap.getOutputSizes(SurfaceTexture.class)[0];
            if (ActivityCompat.checkSelfPermission(this, Manifest.permission.CAMERA) != PackageManager.PERMISSION_GRANTED) {
                ActivityCompat.requestPermissions(this, new String[]{Manifest.permission.CAMERA}, 1);
                heartRateMeasureText.setText("Measure Heart Rate");
                return;
            }
            cameraManager.openCamera(cameraId, cameraStateCallback, null);
        } catch (CameraAccessException e) {
            e.printStackTrace();
        }
    }

    private void MeasureHeartRate(){
        double sumPeakBeats = 0.0;
        for(int i=0; i<peakBeats.size()-1; i++){
            sumPeakBeats += (peakBeats.get(i + 1) - peakBeats.get(i));
        }
        double peakRateAverage = sumPeakBeats / (peakBeats.size() - 1);
        heartRate = (60000 / (peakRateAverage));
    }

    public void onSensorChanged(SensorEvent sensorEvent){
        if(sensorEvent.sensor.getType() == Sensor.TYPE_ACCELEROMETER){
            accelerometerValueX.add(sensorEvent.values[0]);
            accelerometerValueY.add(sensorEvent.values[1]);
            accelerometerValueZ.add(sensorEvent.values[2]);
        }
    }

    @Override
    public void onAccuracyChanged(Sensor sensor, int accuracy) {

    }

    private void MeasureRespiratoryRate(){
        int count = 0;
        for(int i=1;i<accelerometerValueY.size();i+=(accelerometerValueY.size())/40){
            if((accelerometerValueY.get(i-1)<accelerometerValueY.get(i))&&(accelerometerValueY.get(i+1)<accelerometerValueY.get(i))){
                count++;
            }
        }

        RespiratoryRate = 60000*count/45000;
        manageAccelerometer.unregisterListener(this);
    }

    public void ClickSymptoms() {
        Intent symptomIntent = new Intent(this, SymptomActivity.class);
        symptomIntent.putExtra(EXTRA_MESSAGE, symptomId);
        startActivity(symptomIntent);
    }

}