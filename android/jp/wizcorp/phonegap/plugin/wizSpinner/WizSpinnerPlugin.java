package jp.wizcorp.phonegap.plugin.wizSpinner;

import org.apache.cordova.CallbackContext;
import org.apache.cordova.CordovaPlugin;
import org.json.JSONArray;
import org.json.JSONException;

import android.util.Log;

/**
 *
 * @author WizCorp Inc. [ Incorporated Wizards ]
 * @copyright 2013
 * @file WizSpinnerPlugin for Cordova
 * @about Handle JavaScript API calls from PhoneGap to WizSpinner
 *
 */
public class WizSpinnerPlugin extends CordovaPlugin {

	private String TAG = "WizSpinnerPlugin";

	@Override
	public void onDestroy () {
		Log.i(TAG, "[HIDE SPINNER] onDestroy");
		WizSpinner.hide(cordova.getActivity());
		super.onDestroy();
	}

	@Override
	public boolean execute(String action, JSONArray args, CallbackContext callbackContext) throws JSONException {

		if (action.equals("show")) {
			Log.i(TAG, "[SHOW SPINNER] ******* ");
			WizSpinner.show(cordova.getActivity());
			callbackContext.success();
			return true;
		} else if (action.equals("hide")) {
			Log.i(TAG, "[HIDE SPINNER] ******* ");
			WizSpinner.hide(cordova.getActivity());
			callbackContext.success();
			return true;
		}

		return false;
	}

}
