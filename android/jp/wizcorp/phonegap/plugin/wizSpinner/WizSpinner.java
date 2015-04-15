package jp.wizcorp.phonegap.plugin.wizSpinner;

import android.app.Activity;
import android.app.Dialog;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.Gravity;
import android.view.Window;
import android.view.WindowManager;
import android.view.WindowManager.LayoutParams;
import android.view.animation.AnimationUtils;

public class WizSpinner {

  private static Dialog dialog;
  private final static String TAG = "WizSpinner";
  public static boolean isVisible = false;

  public static void show(Activity activity) {
    // create and show the spinner

    final Activity _ctx = activity;

    if ( !isVisible ) {
      Log.i(TAG, "[display spinner] ******* ");

      activity.runOnUiThread(
        new Runnable() {
          public void run() {
            int layoutId = _ctx.getResources().getIdentifier("loading_spinner", "layout",_ctx.getApplicationContext().getPackageName());

            dialog = new Dialog(_ctx);

            Window window = dialog.getWindow();
            window.setBackgroundDrawable(new ColorDrawable(0));

            WindowManager.LayoutParams wlp = window.getAttributes();
            wlp.gravity = Gravity.BOTTOM;
            window.clearFlags(LayoutParams.FLAG_DIM_BEHIND);
            window.setAttributes(wlp);

            dialog.setContentView(layoutId);
            dialog.setCancelable(false);
            dialog.show();
          }
        }
      );

      isVisible = true;
    }
  }

  public static void hide(Activity activity) {
    // hide the spinner
    if ( isVisible ) {
      Log.i(TAG, "[Hiding spinner] ******* ");

      activity.runOnUiThread(
        new Runnable() {
          public void run() {
            dialog.dismiss();
          }
        }
      );
      isVisible = false;
    }
  }
}
