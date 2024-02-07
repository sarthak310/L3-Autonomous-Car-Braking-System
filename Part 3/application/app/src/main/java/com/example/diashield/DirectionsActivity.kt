package com.example.diashield;

import androidx.appcompat.app.AppCompatActivity
import android.os.Bundle
import android.util.Log
import android.view.View
import android.widget.Button
import android.widget.EditText
import android.widget.TextView
import android.widget.Toast
import com.android.volley.Request
import com.android.volley.RequestQueue
import com.android.volley.Response
import com.android.volley.VolleyError
import com.android.volley.toolbox.StringRequest
import com.android.volley.toolbox.Volley
import org.json.JSONArray
import org.json.JSONException
import org.json.JSONObject

class DirectionsActivity : MainActivity() {

    private lateinit var editTextStart: EditText
    private lateinit var editTextEnd: EditText
    private lateinit var buttonCalculate: Button
    private lateinit var textViewSpeedDiff: TextView
    private lateinit var textViewWL: TextView

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        setContentView(R.layout.activity_distance_calculation)

        editTextStart = findViewById(R.id.editTextStart)
        editTextEnd = findViewById(R.id.editTextEnd)
        buttonCalculate = findViewById(R.id.buttonCalculate)
        textViewSpeedDiff = findViewById(R.id.textViewSpeedDiff)
        textViewWL = findViewById(R.id.textViewWL)

        buttonCalculate.setOnClickListener {
            calculateDifference()
        }
    }



// ...

    private fun calculateDifference() {
        val startCoordinates = editTextStart.text.toString()
        val endCoordinates = editTextEnd.text.toString()

        val apiKey = "AIzaSyC9wZy_2KEeNDwrnorOhpsviUmLmJvT3RE"

        val distanceMatrixUrl = "https://maps.googleapis.com/maps/api/distancematrix/json?" +
                "origins=$startCoordinates" +
                "&destinations=$endCoordinates" +
                "&departure_time=now" +
                "&key=$apiKey"

        val queue = Volley.newRequestQueue(this)
        val stringRequest = StringRequest(Request.Method.GET, distanceMatrixUrl,
                Response.Listener { response ->
                    try {
                        Log.d("JSON_RESPONSE", response)

                        val jsonResponse = JSONObject(response)
                        val rows = jsonResponse.getJSONArray("rows")

                        if (rows.length() > 0) {
                            val row = rows.getJSONObject(0)
                            val elements = row.getJSONArray("elements")

                            if (elements.length() > 0) {
                                val element = elements.getJSONObject(0)

                                val distanceText = element.getJSONObject("distance").getInt("value").toDouble()
                                val durationText = element.getJSONObject("duration").getInt("value").toDouble()
                                val durationInTrafficText = element.getJSONObject("duration_in_traffic").getInt("value").toDouble()
                                val normalDurationInHours = durationText / 3600
                                val currentDurationInHours = durationInTrafficText / 3600
                                val distanceInMiles = distanceText / 1609
                                val normalSpeed = distanceInMiles / normalDurationInHours

                                val currentSpeed = distanceInMiles / currentDurationInHours

                                val speedDiff = normalSpeed - currentSpeed

                                var WL = ""
                                if (durationText > durationInTrafficText) {
                                    WL = "LCW"
                                } else {
                                    WL = "HCW"
                                }
                                textViewSpeedDiff.text = "Difference in speeds: $speedDiff"
                                textViewWL.text = "Workload: $WL"

                            }
                        } else {
                            Toast.makeText(this, "No data found", Toast.LENGTH_SHORT).show()
                        }
                    } catch (e: JSONException) {
                        e.printStackTrace()
                        Toast.makeText(this, "Error parsing data", Toast.LENGTH_SHORT).show()
                    }
                },
                Response.ErrorListener { error ->
                    Toast.makeText(this, "Error fetching data", Toast.LENGTH_SHORT).show()
                })

        queue.add(stringRequest)
    }



}
