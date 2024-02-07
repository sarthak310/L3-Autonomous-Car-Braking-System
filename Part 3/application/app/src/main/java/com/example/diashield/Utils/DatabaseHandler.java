package com.example.diashield.Utils;

import android.content.Context;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;
import android.database.sqlite.SQLiteOpenHelper;
import android.widget.Toast;

import com.example.diashield.MainActivity;

public class DatabaseHandler extends SQLiteOpenHelper {

    private static final int VERSION = 1;
    private static final String NAME = "ssshah45.db";
    private static final String TABLE = "User_Response";
    private static final String CREATE_TABLE = "Create Table if not exists " +TABLE+ " (" +
            "record_id integer primary key autoincrement, " +
            "heartrate double default 0.0, " +
            "respiratoryrate double default 0.0, " +
            "nausea float default 0.0, " +
            "headache float default 0.0, " +
            "diarrhea float default 0.0, " +
            "sorethroat float default 0.0, " +
            "fever float default 0.0, " +
            "muscleache float default 0.0, " +
            "lossofsmellortaste float default 0.0, " +
            "cough float default 0.0, " +
            "shortnessofbreath float default 0.0, " +
            "feelingtired float default 0.0);";

    private SQLiteDatabase db;

    public DatabaseHandler(Context context) {
        super(context, NAME, null, VERSION);
    }

    @Override
    public void onCreate(SQLiteDatabase db) {
        db.execSQL(CREATE_TABLE);
    }

    @Override
    public void onUpgrade(SQLiteDatabase db, int oldVersion, int newVersion) {
        // Drop older table if existed
        db.execSQL("DROP TABLE IF EXISTS "+TABLE);
        // Create tables again
        onCreate(db);
    }

    public void openDatabase() {
        db = this.getWritableDatabase();
    }

    public void uploadSigns(double heartRate, double respiratoryRate) {
        db.execSQL("Insert Into " + TABLE + " (heartrate, respiratoryrate) " +
                "values(" + heartRate + ", " + respiratoryRate + ");");
    }

    public void uploadSymptoms(String selectedSymptom, float symptomRatings){
        db.beginTransaction();
        try {
            db.execSQL("Update "+TABLE+" Set "+selectedSymptom+" = "+symptomRatings+" " +
                    " Where record_id in (select record_id from "+TABLE+" order by record_id desc LIMIT 1);");
            db.setTransactionSuccessful();
        }catch (SQLiteException e){
            e.printStackTrace();
        }finally {
            db.endTransaction();
        }
    }


}
