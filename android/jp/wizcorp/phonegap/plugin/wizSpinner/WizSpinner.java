package jp.wizcorp.phonegap.plugin.wizSpinner;

import android.app.Activity;
import android.app.Dialog;
import android.graphics.drawable.ColorDrawable;
import android.util.Log;
import android.view.Gravity;
import android.view.Window;
import android.view.WindowManager;
import android.view.animation.AnimationUtils;
import android.view.View;

public class WizSpinner {

  private static Dialog dialog;
  private final static String TAG = "WizSpinner";
  public static boolean isVisible = false;

  public static void show(Activity activity) {
    // create and show the spinner

    final Activity _ctx = activity;

    // check if is activity is not finished to prevent crashes (http://dimitar.me/android-displaying-dialogs-from-background-threads/)
    if ( !isVisible && !activity.isFinishing() ) {
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
            window.clearFlags(WindowManager.LayoutParams.FLAG_DIM_BEHIND);
            window.setAttributes(wlp);

            dialog.setContentView(layoutId);
            dialog.setCancelable(false);
            dialog.getWindow().addFlags(WindowManager.LayoutParams.FLAG_FULLSCREEN | WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE);

            // force immersive fullscreen if possible (copying of ctx system visibility did not work on tablets)
            if (android.os.Build.VERSION.SDK_INT >= android.os.Build.VERSION_CODES.KITKAT) {
              dialog.getWindow().getDecorView().setSystemUiVisibility(
                      View.SYSTEM_UI_FLAG_LAYOUT_STABLE
                              | View.SYSTEM_UI_FLAG_LAYOUT_HIDE_NAVIGATION
                              | View.SYSTEM_UI_FLAG_LAYOUT_FULLSCREEN
                              | View.SYSTEM_UI_FLAG_HIDE_NAVIGATION
                              | View.SYSTEM_UI_FLAG_FULLSCREEN
                              | View.SYSTEM_UI_FLAG_IMMERSIVE_STICKY
              );
            }

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

      if ( !activity.isFinishing() ) { // hopefully fixes crashes where view not attached to window manager
        activity.runOnUiThread(
                new Runnable() {
                  public void run() {
                    if ( dialog.getWindow() != null ) { // hopefully fixes crashes where view not attached to window manager
                      dialog.dismiss();
                    }
                  }
                }
        );
      }
      isVisible = false;
    }
  }
}
