import { Component } from '@angular/core';
import { Router } from '@angular/router';
import { Platform } from '@ionic/angular';
import { Catapush } from 'plugins/catapush-cordova-sdk/types';

declare var Catapush: Catapush;

@Component({
  selector: 'app-root',
  templateUrl: 'app.component.html',
  styleUrls: ['app.component.scss'],
})
export class AppComponent {

  constructor(public router: Router, public platform: Platform) {
    this.platform.ready().then((readySource) => {
      console.log('Platform ready from', readySource);

      Catapush.enableLog(
        () => {
          console.log('Catapush enableLog success');
        },
        (message: string) => {
          console.log('Catapush enableLog failed: ' + message);
        },
        true
      );

      Catapush.init(
        () => {
          console.log('Catapush init success');
        },
        (message: string) => {
          console.log('Catapush init failed: ' + message);
        },
        '3ef0930b34f558c963f3a9a7c029ee48'
      );

      Catapush.setUser(
        () => {
          console.log('Catapush setUser success');

          Catapush.start(
            () => {
              console.log('Catapush start success');

              this.router.navigate(['messages']);
            },
            (message: string) => {
              console.log('Catapush start failed: ' + message);
            }
          );
        },
        (message: string) => {
          console.log('Catapush setUser failed: ' + message);
        },
        'ios',
        'ios'
      );

    });
  }

}
