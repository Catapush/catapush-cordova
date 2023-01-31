import { Component, HostListener } from '@angular/core';
import { FileChooser } from '@ionic-native/file-chooser';
import { Catapush, CatapushError, CatapushFile, CatapushMessage, CatapushState } from 'plugins/catapush-cordova-sdk/types';

declare var Catapush: Catapush;

@Component({
  selector: 'app-message-list',
  templateUrl: './message-list.component.html',
  styleUrls: ['./message-list.component.scss']
})
export class MessageListComponent {
  messages: CatapushMessage[] = [];
  attachments: Map<string, CatapushFile> = new Map<string, CatapushFile>();
  newMessageBody: string = '';

  constructor() {
    this.loadMessages();

    Catapush.pauseNotifications(
      () => console.log('Catapush pauseNotifications success'),
      (message: string) => console.log('Catapush pauseNotifications failed: ' + message)
    );

    Catapush.setCatapushMessageDelegate({
      catapushMessageReceived: (message: CatapushMessage) => this.loadMessages(),
      catapushMessageSent: (message: CatapushMessage) => this.loadMessages(),
      catapushNotificationTapped: (message: CatapushMessage) => console.log('Catapush notification tapped for message:' + message.id),
    })

    Catapush.setCatapushStateDelegate({
      catapushStateChanged: (state: CatapushState) => console.log("Catapush state is now: " + state),
      catapushHandleError: (error: CatapushError) => console.error("Catapush error. code: " + error.code + ", description: " + error.event),
    })
  }

  @HostListener('window:beforeunload', ['$event'])
  onBeforeUnload(): void {
    Catapush.resumeNotifications(
      () => console.log('Catapush resumeNotifications success'),
      (message: string) => console.log('Catapush resumeNotifications failed: ' + message)
    );

    Catapush.setCatapushMessageDelegate(null);
    Catapush.setCatapushStateDelegate(null);
  }

  trackById(index: number, data: any): number {
    return data.id + data.state;
  }

  loadMessages(): void {
    Catapush.allMessages(
      (messages: CatapushMessage[]) => {
        console.log('Catapush allMessages success');
        messages.forEach(message => {
          if (message.hasAttachment) {
            this.preloadAttachment(message);
          }
        });
        this.messages = messages.reverse();
      },
      (message: string) => {
        console.log('Catapush allMessages failed: ' + message);
      }
    );
  }

  preloadAttachment(message: CatapushMessage): void {
    if (this.attachments.has(message.id)) {
      return;
    }
    Catapush.getAttachmentUrlForMessage(
      (attachment: CatapushFile) => {
        this.attachments.set(message.id, attachment);
        console.log('Catapush getAttachmentUrlForMessage success: ' + attachment.url);
      },
      (message: string) => {
        console.log('Catapush getAttachmentUrlForMessage failed: ' + message);
      },
      message
    );
  }

  sendMessage(): void {
    Catapush.sendMessage(
      () => {
        this.newMessageBody = '';
        this.loadMessages();
        console.log('Catapush sendMessage success');
      },
      (message: string) => {
        console.log('Catapush sendMessage failed: ' + message);
      },
      { body: this.newMessageBody }
    );
  }

  sendAttachment(): void {
    FileChooser.open({ mime: 'image/*' })
      .then(uri => {
        Catapush.sendMessage(
          () => {
            this.newMessageBody = '';
            this.loadMessages();
            console.log('Catapush sendAttachment success');
          },
          (message: string) => {
            console.log('Catapush sendAttachment failed: ' + message);
          },
          { body: '', file: { mimeType: '', url: uri } }
        );
      })
      .catch(e => console.log('Catapush file choice failed: ' + e));
  }

}