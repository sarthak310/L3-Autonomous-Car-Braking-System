package com.example.diashield;

import androidx.appcompat.app.AppCompatActivity;

import android.content.Context;
import android.database.SQLException;
import android.database.sqlite.SQLiteDatabase;
import android.database.sqlite.SQLiteException;
import android.os.Bundle;
import android.os.Environment;
import android.util.Log;
import android.view.View;
import android.widget.ArrayAdapter;
import android.widget.RatingBar;
import android.widget.Spinner;
import android.widget.Toast;

import com.example.diashield.Utils.DatabaseHandler;

public class SymptomActivity extends MainActivity {

    Spinner spinner;
    String[] symptomDatabaseColumn = new String[] {
            "nausea", "headache", "diarrhea", "sorethroat", "fever", "muscleache", "lossofsmellortaste",
            "cough", "shortnessofbreath", "feelingtired"
    };
    RatingBar ratingBar;

    @Override
    protected void onCreate(Bundle savedInstanceState) {
        super.onCreate(savedInstanceState);
        setContentView(R.layout.activity_symptom);

        db = new DatabaseHandler(this);
        db.openDatabase();

        String[] symptomList = new String[] {
                "Nausea", "Headache", "diarrhea", "Sore Throat", "Fever", "Muscle Ache", "Loss of Smell or Taste",
                "Cough", "Shortness of Breath", "Feeling tired"
        };
        spinner = (Spinner) findViewById(R.id.spinnerSymptomList);
        ArrayAdapter<String> adapter = new ArrayAdapter<String>(this, android.R.layout.simple_spinner_item, symptomList);
        adapter.setDropDownViewResource(android.R.layout.simple_spinner_dropdown_item);
        spinner.setAdapter(adapter);

        ratingBar = (RatingBar)findViewById(R.id.ratingBar);
    }

    public void onClickUploadSymptoms(View view) {
            String selectedSymptom = symptomDatabaseColumn[spinner.getSelectedItemPosition()];
            float symptomRatings = ratingBar.getRating();
            ratingBar.setRating(0.0f);
            db.uploadSymptoms(selectedSymptom, symptomRatings);
            Toast.makeText(SymptomActivity.this, "Symptom Rating Uploaded Successfully", Toast.LENGTH_LONG).show();

    }
}