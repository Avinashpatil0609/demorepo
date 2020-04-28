import json

def lambda_handler(event, context):
    response_body = """
 <html lang="en">
 <style>
    h1 { color: #73757d; }
  </style>
   <head>
     <meta charset="utf-8">
     <title>Tc1</title>
   </head>
   <body>
   <h1>Hello from Tc1</h1>
   </body>
 </html>"""
    return {
    "statusCode": 200,
    "body": response_body,
    "headers": {
        'Content-Type': 'text/html',
    }
    
}
