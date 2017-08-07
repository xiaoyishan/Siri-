//
//  SiriButton.m
//  Siri语音识别
//
//  Created by Sundear on 2017/8/7.
//  Copyright © 2017年 xiaoyishan. All rights reserved.
//

#import "SiriButton.h"

@implementation SiriButton


- (instancetype)initWithFrame:(CGRect)frame
{
    self = [super initWithFrame:frame];
    if (self) {
        [self PrepareLimit];
    }
    return self;
}

- (instancetype)initWithCoder:(NSCoder *)coder
{
    self = [super initWithCoder:coder];
    if (self) {
        [self PrepareLimit];
    }
    return self;
}



-(void)PrepareLimit{

    _audioEngine = [[AVAudioEngine alloc] init];

    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"en"];//zh_CN
    _speechRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];
    _speechRecognizer.delegate = self;

    //请求权限
    [SFSpeechRecognizer  requestAuthorization:^(SFSpeechRecognizerAuthorizationStatus status) {
        dispatch_async(dispatch_get_main_queue(), ^{
            switch (status) {
                case SFSpeechRecognizerAuthorizationStatusNotDetermined:
                    self.enabled = NO;
                    [self setTitle:@"语音识别未授权" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusDenied:
                    self.enabled = NO;
                    [self setTitle:@"用户未授权使用语音识别" forState:UIControlStateDisabled];
                    break;
                case SFSpeechRecognizerAuthorizationStatusRestricted:
                    self.enabled = NO;
                    [self setTitle:@"语音识别在这台设备上受到限制" forState:UIControlStateDisabled];

                    break;
                case SFSpeechRecognizerAuthorizationStatusAuthorized:
                    self.enabled = YES;
                    [self setTitle:@"开始录音" forState:UIControlStateNormal];
                    break;

                default:
                    break;
            }

        });
    }];


    [self addTarget:self action:@selector(recordButtonClicked:) forControlEvents:UIControlEventTouchUpInside];
}


#pragma mark - SFSpeechRecognizerDelegate
- (void)speechRecognizer:(SFSpeechRecognizer *)speechRecognizer availabilityDidChange:(BOOL)available{
    if (available) {
        self.enabled = YES;
        [self setTitle:@"开始录音" forState:UIControlStateNormal];
    }
    else{
        self.enabled = NO;
        [self setTitle:@"语音识别不可用" forState:UIControlStateDisabled];
    }
}

- (IBAction)recordButtonClicked:(UIButton *)sender {
    if (self.audioEngine.isRunning) {
        [self.audioEngine stop];
        if (_recognitionRequest) {
            [_recognitionRequest endAudio];
        }
        self.enabled = NO;
        [self setTitle:@"正在停止" forState:UIControlStateDisabled];

    }
    else{
        [self startRecording];
        [self setTitle:@"停止" forState:UIControlStateNormal];

    }
}


- (void)startRecording{
    if (_recognitionTask) {
        [_recognitionTask cancel];
        _recognitionTask = nil;
    }

    AVAudioSession *audioSession = [AVAudioSession sharedInstance];
    NSError *error;
    [audioSession setCategory:AVAudioSessionCategoryRecord error:&error];
    NSParameterAssert(!error);
    [audioSession setMode:AVAudioSessionModeMeasurement error:&error];
    NSParameterAssert(!error);
    [audioSession setActive:YES withOptions:AVAudioSessionSetActiveOptionNotifyOthersOnDeactivation error:&error];
    NSParameterAssert(!error);

    _recognitionRequest = [[SFSpeechAudioBufferRecognitionRequest alloc] init];
    AVAudioInputNode *inputNode = self.audioEngine.inputNode;
    NSAssert(inputNode, @"录入设备没有准备好");
    NSAssert(_recognitionRequest, @"请求初始化失败");
    _recognitionRequest.shouldReportPartialResults = YES;
    __weak typeof(self) weakSelf = self;
    _recognitionTask = [self.speechRecognizer recognitionTaskWithRequest:_recognitionRequest resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        BOOL isFinal = NO;
        if (result) {

            if(self.BridgingBlock)self.BridgingBlock(result.bestTranscription.formattedString);

            isFinal = result.isFinal;
        }
        if (error || isFinal) {
            [self.audioEngine stop];
            [inputNode removeTapOnBus:0];
            strongSelf.recognitionTask = nil;
            strongSelf.recognitionRequest = nil;
            self.enabled = YES;
            [self setTitle:@"开始" forState:UIControlStateNormal];
        }

    }];

    AVAudioFormat *recordingFormat = [inputNode outputFormatForBus:0];
    //在添加tap之前先移除上一个  不然有可能报"Terminating app due to uncaught exception 'com.apple.coreaudio.avfaudio',"之类的错误
    [inputNode removeTapOnBus:0];
    [inputNode installTapOnBus:0 bufferSize:1024 format:recordingFormat block:^(AVAudioPCMBuffer * _Nonnull buffer, AVAudioTime * _Nonnull when) {
        __strong typeof(weakSelf) strongSelf = weakSelf;
        if (strongSelf.recognitionRequest) {
            [strongSelf.recognitionRequest appendAudioPCMBuffer:buffer];
        }
    }];

    [self.audioEngine prepare];
    [self.audioEngine startAndReturnError:&error];
    NSParameterAssert(!error);
//    [self setTitle:@"正在录音" forState:UIControlStateNormal];
}




-(void)AddListenBlock:(ReceiveBlock)Receive{
    self.BridgingBlock = Receive;//桥
}

-(void)AddListenDataUrl:(NSURL*)url Block:(void(^)(NSString *ShortWord))Receive{

    NSLocale *local =[[NSLocale alloc] initWithLocaleIdentifier:@"en"];//zh_CN
    SFSpeechRecognizer *localRecognizer =[[SFSpeechRecognizer alloc] initWithLocale:local];

    if (!url) return;
    SFSpeechURLRecognitionRequest *res =[[SFSpeechURLRecognitionRequest alloc] initWithURL:url];
    [localRecognizer recognitionTaskWithRequest:res resultHandler:^(SFSpeechRecognitionResult * _Nullable result, NSError * _Nullable error) {
        if (!error) {

            if(Receive)Receive(result.bestTranscription.formattedString);

        }else{
            NSLog(@"语音识别解析失败,%@",error);
        }

    }];

}

@end
