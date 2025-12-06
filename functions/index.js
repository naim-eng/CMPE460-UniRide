const functions = require('firebase-functions');
const admin = require('firebase-admin');
const axios = require('axios');

admin.initializeApp();

// Store your Google API key in Firebase environment config (see instructions below)
const GOOGLE_API_KEY = functions.config().google?.api_key || 'YOUR_API_KEY_HERE';

/**
 * Google Places Autocomplete Proxy
 * Usage: POST /placesAutocomplete with body: { query: "search term" }
 */
exports.placesAutocomplete = functions.https.onCall(async (data, context) => {
  // Optional: Authenticate requests
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use this function.'
    );
  }

  const { query } = data;

  if (!query || query.trim().length < 2) {
    return { predictions: [] };
  }

  try {
    const response = await axios.get(
      'https://maps.googleapis.com/maps/api/place/autocomplete/json',
      {
        params: {
          input: query,
          key: GOOGLE_API_KEY,
          location: '26.0667,50.5577', // Bahrain coordinates
          radius: 50000,
          components: 'country:bh',
          types: 'establishment|geocode'
        }
      }
    );

    if (response.data.status !== 'OK' && response.data.status !== 'ZERO_RESULTS') {
      console.error('Google Places API error:', response.data);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to fetch location suggestions'
      );
    }

    // Return predictions with limited data to reduce bandwidth
    const predictions = (response.data.predictions || []).slice(0, 5).map(p => ({
      placeId: p.place_id,
      description: p.description
    }));

    return { predictions };
  } catch (error) {
    console.error('Error calling Places API:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error fetching location suggestions'
    );
  }
});

/**
 * Google Place Details Proxy
 * Usage: POST /placeDetails with body: { placeId: "ChIJ..." }
 */
exports.placeDetails = functions.https.onCall(async (data, context) => {
  // Optional: Authenticate requests
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use this function.'
    );
  }

  const { placeId } = data;

  if (!placeId) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'placeId is required'
    );
  }

  try {
    const response = await axios.get(
      'https://maps.googleapis.com/maps/api/place/details/json',
      {
        params: {
          place_id: placeId,
          key: GOOGLE_API_KEY,
          fields: 'geometry'
        }
      }
    );

    if (response.data.status !== 'OK') {
      console.error('Google Place Details API error:', response.data);
      throw new functions.https.HttpsError(
        'internal',
        'Failed to fetch place details'
      );
    }

    const location = response.data.result?.geometry?.location;
    if (!location) {
      throw new functions.https.HttpsError(
        'not-found',
        'Location not found for this place'
      );
    }

    return {
      lat: location.lat,
      lng: location.lng
    };
  } catch (error) {
    console.error('Error calling Place Details API:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error fetching place details'
    );
  }
});

/**
 * Google Geocoding (Reverse) Proxy
 * Usage: POST /reverseGeocode with body: { lat: 26.0667, lng: 50.5577 }
 */
exports.reverseGeocode = functions.https.onCall(async (data, context) => {
  // Optional: Authenticate requests
  if (!context.auth) {
    throw new functions.https.HttpsError(
      'unauthenticated',
      'User must be authenticated to use this function.'
    );
  }

  const { lat, lng } = data;

  if (lat === undefined || lng === undefined) {
    throw new functions.https.HttpsError(
      'invalid-argument',
      'lat and lng are required'
    );
  }

  try {
    const response = await axios.get(
      'https://maps.googleapis.com/maps/api/geocode/json',
      {
        params: {
          latlng: `${lat},${lng}`,
          key: GOOGLE_API_KEY
        }
      }
    );

    if (response.data.status !== 'OK') {
      console.error('Google Geocoding API error:', response.data);
      return { address: null };
    }

    const results = response.data.results || [];
    const address = results.length > 0 ? results[0].formatted_address : null;

    return { address };
  } catch (error) {
    console.error('Error calling Geocoding API:', error);
    throw new functions.https.HttpsError(
      'internal',
      'Error fetching address'
    );
  }
});
