{
  "WFWorkflowActions": [
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.gettext",
      "WFWorkflowActionParameters": {
        "WFTextActionText": "Capture to EMRY"
      }
    },
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.setvariable",
      "WFWorkflowActionParameters": {
        "WFVariableName": "CapturedText"
      }
    },
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.date",
      "WFWorkflowActionParameters": {
        "WFDateActionMode": "Current Date"
      }
    },
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.format.date",
      "WFWorkflowActionParameters": {
        "WFDateFormatStyle": "Custom",
        "WFDateFormat": "yyyy-MM-dd HH:mm:ss"
      }
    },
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.setvariable",
      "WFWorkflowActionParameters": {
        "WFVariableName": "Timestamp"
      }
    },
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.getcontentsofurl",
      "WFWorkflowActionParameters": {
        "WFHTTPMethod": "POST",
        "WFHTTPBodyType": "JSON",
        "WFURL": "http://YOUR_PC_IP:8766/capture",
        "WFJSONValues": {
          "role": "user",
          "content": "{{CapturedText}}",
          "platform": "ios-shortcut",
          "url": "",
          "metadata": {
            "source": "iPhone",
            "timestamp": "{{Timestamp}}"
          }
        }
      }
    },
    {
      "WFWorkflowActionIdentifier": "is.workflow.actions.showresult",
      "WFWorkflowActionParameters": {
        "Text": "Captured to EMRY! ✓"
      }
    }
  ],
  "WFWorkflowClientVersion": "2302.0.4",
  "WFWorkflowClientRelease": "2.2",
  "WFWorkflowMinimumClientVersion": 1200,
  "WFWorkflowMinimumClientRelease": "2.0",
  "WFWorkflowIcon": {
    "WFWorkflowIconStartColor": 4282601983,
    "WFWorkflowIconGlyphNumber": 59511
  },
  "WFWorkflowTypes": [
    "ActionExtension"
  ],
  "WFWorkflowInputContentItemClasses": [
    "WFStringContentItem",
    "WFURLContentItem"
  ]
}
