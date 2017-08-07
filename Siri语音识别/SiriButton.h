//
//  SiriButton.h
//  Siri语音识别
//
//  Created by Sundear on 2017/8/7.
//  Copyright © 2017年 xiaoyishan. All rights reserved.
//

#import <UIKit/UIKit.h>

#import <Speech/Speech.h>
#import <AVFoundation/AVFoundation.h>

@interface SiriButton : UIButton<SFSpeechRecognizerDelegate>

@property (nonatomic,strong) AVAudioEngine *audioEngine; //音频节点
@property (nonatomic,strong) SFSpeechRecognizer *speechRecognizer; //识别器
@property (nonatomic,strong) SFSpeechRecognitionTask *recognitionTask; //识别任务
@property (nonatomic,strong) SFSpeechAudioBufferRecognitionRequest *recognitionRequest; //识别请求


//语音识别
typedef void (^ReceiveBlock)(NSString *ShortWord);
@property (nonatomic, copy) ReceiveBlock BridgingBlock;
-(void)AddListenBlock:(ReceiveBlock)Receive;

//本地文件识别
-(void)AddListenDataUrl:(NSURL*)url Block:(void(^)(NSString *ShortWord))Receive;

@end
