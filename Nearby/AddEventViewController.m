//
//  AddEventViewController.m
//  Nearby
//
//  Created by Piotr Czubak on 11/26/15.
//  Copyright © 2015 EventAppOrg. All rights reserved.
//

#import "AddEventViewController.h"
#import "Event.h"
#import "EventDetailViewController.h"
#import "EventViewController.h"
#import <Parse/Parse.h>

@interface AddEventViewController () <UIImagePickerControllerDelegate,UINavigationControllerDelegate>

@property (weak, nonatomic) IBOutlet UIScrollView *scrollView;
@property (weak, nonatomic) IBOutlet UITextField *eventNameTextField;
@property (weak, nonatomic) IBOutlet UITextField *addressTextField;
@property (weak, nonatomic) IBOutlet UIDatePicker *datePicker;
@property (weak, nonatomic) IBOutlet UITextField *categoryTextField;
@property (weak, nonatomic) IBOutlet UISwitch *privateSwitch;
@property (weak, nonatomic) IBOutlet UITextView *descriptionTextField;
@property (weak, nonatomic) IBOutlet UITextField *inviteUserTextField;
@property (weak, nonatomic) IBOutlet UILabel *errorLabel;
@property (strong, nonatomic) NSMutableSet *invitees;
@property (weak, nonatomic) IBOutlet UIImageView *imageView;

@end

@implementation AddEventViewController

UITextField *activeField;
UILabel *imageLabel;

- (void)viewDidLoad {
    self.title = @"Nearby";
    [self.errorLabel setHidden:YES];
    self.navigationItem.rightBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"Add Event" style:UIBarButtonItemStyleDone target:self action:@selector(addEvent)];
    [self registerForKeyboardNotifications];
    self.invitees = [NSMutableSet set];
    [self.privateSwitch setOn:NO];
    [super viewDidLoad];
    
    imageLabel = [[UILabel alloc] initWithFrame:CGRectMake(10, 10, 300, 20)];
    [imageLabel setTextColor:[UIColor blackColor]];
    [imageLabel setBackgroundColor:[UIColor clearColor]];
    [imageLabel setText:@"Click here to select your image"];
    imageLabel.frame = CGRectMake(self.imageView.frame.origin.x, self.imageView.frame.origin.y - imageLabel.frame.size.height+50, self.imageView.frame.size.width, imageLabel.frame.size.height);
    imageLabel.textAlignment = NSTextAlignmentCenter;
    [imageLabel setFont:[UIFont fontWithName: @"Trebuchet MS" size: 15.0f]];
    [self.imageView addSubview:imageLabel];
}

- (IBAction)onTap:(id)sender {
    [self showCameraAction:nil];
}

- (void)addEvent {
    // TODO: add image
    Event *newEvent = [[Event alloc] init];
    if ([self.eventNameTextField.text isEqualToString:@""]) {
        return;
    }
    [newEvent setOwner:[PFUser currentUser]];
    [newEvent setEventName:self.eventNameTextField.text];
    [newEvent setAddress:self.addressTextField.text];
    [newEvent setCategory:self.categoryTextField.text];
    [newEvent setDescriptionContent:self.descriptionTextField.text];
    [newEvent setIsPrivate:[NSNumber numberWithBool:self.privateSwitch.isOn]];
    [newEvent setEventDate:[self.datePicker date]];
    
    NSMutableArray *invitees = [[NSMutableArray alloc] init];
    EventUser *eu = [[EventUser alloc] init];
    eu.user = newEvent.owner;
    eu.status = [[NSNumber alloc] initWithInt:1];
    [invitees addObject:eu];
    for (PFUser *u in self.invitees) {
        EventUser *invitee = [[EventUser alloc] init];
        invitee.user = u;
        invitee.status = [[NSNumber alloc] initWithInt:1];
        [invitees addObject:invitee];
    }
    [newEvent setEventUsers:invitees];
    
    [newEvent saveInBackgroundWithBlock:^(BOOL succeeded, NSError * _Nullable error) {
        if (succeeded) {
            NSLog(@"Saved event!");
            EventDetailViewController *edvc = [[EventDetailViewController alloc] init];
            edvc.event = newEvent;
            edvc.backToMain = YES;
            self.navigationItem.backBarButtonItem = [[UIBarButtonItem alloc] initWithTitle:@"" style:UIBarButtonItemStylePlain target:nil action:nil];
            [self.navigationController pushViewController:edvc animated:YES];
        } else {
            NSLog(@"Failed: %@", error);
        }
    }];
}

- (void)didReceiveMemoryWarning {
    [super didReceiveMemoryWarning];
}

- (void)textFieldDidBeginEditing:(UITextField *)textField {
    activeField = textField;
}

- (void)textFieldDidEndEditing:(UITextField *)textField {
    activeField = nil;
}

- (void)registerForKeyboardNotifications {
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardDidShow:)
                                                 name:UIKeyboardDidShowNotification object:nil];
    [[NSNotificationCenter defaultCenter] addObserver:self
                                             selector:@selector(keyboardWillBeHidden:)
                                                 name:UIKeyboardWillHideNotification object:nil];
}

- (void)keyboardDidShow:(NSNotification *)notification {
    NSDictionary* info = [notification userInfo];
    CGRect kbRect = [[info objectForKey:UIKeyboardFrameBeginUserInfoKey] CGRectValue];
    
    UIEdgeInsets contentInsets = UIEdgeInsetsMake(self.navigationController.navigationBar.frame.size.height + 12, 0.0, kbRect.size.height, 0.0);
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
    
    CGRect aRect = self.view.frame;
    aRect.size.height -= kbRect.size.height;
    if (!CGRectContainsPoint(aRect, activeField.frame.origin) ) {
        CGPoint scrollPoint = CGPointMake(0.0, activeField.frame.origin.y-kbRect.size.height);
        [self.scrollView setContentOffset:scrollPoint animated:YES];
    }
}

- (void)keyboardWillBeHidden:(NSNotification *)notification {
    UIEdgeInsets contentInsets = UIEdgeInsetsZero;
    self.scrollView.contentInset = contentInsets;
    self.scrollView.scrollIndicatorInsets = contentInsets;
}

- (IBAction)inviteUserAction:(id)sender {
    [self.errorLabel setHidden:YES];
    if (self.inviteUserTextField.text == [[PFUser currentUser] username]) {
        self.errorLabel.text = @"Can't invite yourself";
        [self.errorLabel setHidden:NO];
        return;
    }
    
    PFQuery *query = [PFUser query];
    [query whereKey:@"username" equalTo:self.inviteUserTextField.text];
    
    [query getFirstObjectInBackgroundWithBlock:^(PFObject *object, NSError *error) {
        if (object != nil) {
            NSLog(@"User exist: %@", object);
            [self.invitees addObject:object];
            NSLog(@"Invitees: %@", self.invitees);
        } else {
            NSLog(@"User does not exist");
            self.errorLabel.text = @"User does not exist";
            [self.errorLabel setHidden:NO];
            NSLog(@"Invitees: %@", self.invitees);
        }
    }];
}

-(IBAction)showCameraAction:(id)sender {
    UIImagePickerController *imagePickController = [[UIImagePickerController alloc]init];
    imagePickController.sourceType = UIImagePickerControllerSourceTypePhotoLibrary;;
    imagePickController.delegate = self;
    imagePickController.allowsEditing = TRUE;
    [self presentViewController:imagePickController animated:YES completion:nil];
}

-(void)imagePickerController:(UIImagePickerController *)picker didFinishPickingMediaWithInfo:(NSDictionary *)info {
    UIImage *image = [info objectForKey:UIImagePickerControllerEditedImage];
    self.imageView.image = image;
    [imageLabel setHidden:YES];
    [self dismissViewControllerAnimated:YES completion:nil];
}

@end
