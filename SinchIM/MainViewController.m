#import "MainViewController.h"
#import "MessageTableViewCell.h"
#import <Giphy-iOS/AXCGiphy.h>
#import <AnimatedGIFImageSerialization/AnimatedGIFImageSerialization.h>

typedef NS_ENUM(int, MessageDirection) { Incoming, Outgoing, };

@interface MainViewController () {
  // message entries are 2-element arrays on the form:
  // @[id<SINMessage>, NSNumber* (wrapping MessageDirection)]
  NSMutableArray *_messages;
}
@end

@implementation MainViewController

- (id<SINClient>)client {
  return [(AppDelegate *)[[UIApplication sharedApplication] delegate] client];
}

- (void)awakeFromNib {
  _messages = [NSMutableArray array];
  [self.client messageClient].delegate = self;
}

- (void)sendButtonPressed:(id)sender {

  NSString *destination = self.destination.text;
  NSString *text = self.message.text;

  if ([destination length] == 0 || [text length] == 0) {
    return;
  }

  SINOutgoingMessage *message = [SINOutgoingMessage messageWithRecipient:destination text:text];

  [[self.client messageClient] sendMessage:message];
}

#pragma mark - SINMessageClientDelegate

- (void)messageClient:(id<SINMessageClient>)messageClient didReceiveIncomingMessage:(id<SINMessage>)message {
  [_messages addObject:@[ message, @(Incoming) ]];
  [self.messageView reloadData];
  [self scrollToBottom];
}

- (void)messageSent:(id<SINMessage>)message recipientId:(NSString *)recipientId {
  [_messages addObject:@[ message, @(Outgoing) ]];
  [self.messageView reloadData];
  [self scrollToBottom];
}

- (void)message:(id<SINMessage>)message shouldSendPushNotifications:(NSArray *)pushPairs {
  NSLog(@"Recipient not online. \
          Should notify recipient using push (not implemented in this demo app). \
          Please refer to the documentation for a comprehensive description.");
}

- (void)messageDelivered:(id<SINMessageDeliveryInfo>)info {
  NSLog(@"Message to %@ was successfully delivered", info.recipientId);
}

- (void)messageFailed:(id<SINMessage>)message info:(id<SINMessageFailureInfo>)failureInfo {
  NSLog(@"Failed delivering message to %@. Reason: %@", failureInfo.recipientId,
        [failureInfo.error localizedDescription]);
}

#pragma mark - UITableViewDelegate

- (CGFloat)tableView:(UITableView *)tableView heightForRowAtIndexPath:(NSIndexPath *)indexPath {
    
    NSArray *entry = [_messages objectAtIndex:[indexPath row]];
    id<SINMessage> message = entry[0];
    NSString * messageText = message.text;
    if ([messageText rangeOfString:@"/giphy"].location != NSNotFound) {
        return 205;
    }
    return 90;
}

- (NSInteger)tableView:(UITableView *)tableView numberOfRowsInSection:(NSInteger)section {
  return [_messages count];
}

- (UITableViewCell *)tableView:(UITableView *)tableView cellForRowAtIndexPath:(NSIndexPath *)indexPath {
  NSArray *entry = [_messages objectAtIndex:[indexPath row]];

  id<SINMessage> message = entry[0];
  MessageTableViewCell *cell = [self dequeOrLoadMessageTableViewCell:[entry[1] intValue]];

  cell.message.text = message.text;
  cell.nameLabel.text = message.senderId;
    
    if ([message.text rangeOfString:@"/giphy"].location != NSNotFound)
    {
        [AXCGiphy setGiphyAPIKey:kGiphyPublicAPIKey];
        
        NSArray *components = [message.text componentsSeparatedByString:@" "];
        NSRange range = NSMakeRange(1, [components count] - 1);
        NSArray *otherComponents = [components subarrayWithRange:range];
        NSString *query = [otherComponents componentsJoinedByString:@" "];
        [AXCGiphy giphyTranslationForTerm: query completion:^(AXCGiphy *result, NSError *error) {
            [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                
                NSURLRequest * request = [NSURLRequest requestWithURL:result.originalImage.url];
                [[[NSURLSession sharedSession] dataTaskWithRequest:request completionHandler:^(NSData *data, NSURLResponse *response, NSError *error) {
                    
                    UIImage * image = [UIImage imageWithData:data];
                    [[NSOperationQueue mainQueue] addOperationWithBlock:^{
                        UIImageView* imgv = [[UIImageView alloc] initWithImage:image];
                        imgv.frame =CGRectMake(10, 5, cell.frame.size.width-24, 200);
                        [cell addSubview:imgv];
                    }];
                    
                }] resume];
            }];
        }];
    }

  return cell;
}

- (MessageTableViewCell *)dequeOrLoadMessageTableViewCell:(MessageDirection)direction {

  NSString *identifier =
      [NSString stringWithFormat:@"%@MessageCell", (Incoming == direction) ? @"Incoming" : @"Outgoing"];

  MessageTableViewCell *cell = [self.messageView dequeueReusableCellWithIdentifier:identifier];

  if (!cell) {
    cell = [[NSBundle mainBundle] loadNibNamed:identifier owner:self options:nil][0];
    cell.backgroundColor = [UIColor clearColor];
    cell.contentView.backgroundColor = [UIColor clearColor];
  }
  return cell;
}

#pragma mark -

/*
 Scrolls the message view to the bottom to ensure we always see the latest message.
*/
- (void)scrollToBottom {
  NSIndexPath *indexPath = [NSIndexPath indexPathForRow:(_messages.count - 1)inSection:0];

  [self.messageView scrollToRowAtIndexPath:indexPath atScrollPosition:UITableViewScrollPositionBottom animated:YES];
}

@end
