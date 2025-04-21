//
//  SurveyView.swift
//  Heart Sentry
//
//  Created by Hayden Carlson on 4/17/25.
//


import SwiftUI

struct SurveyView: View {
    @State private var answers: [String: Bool] = [:]
    @State private var showResult = false
    @State private var recommendation = ""

    // List of symptom questions
    private let questions: [String] = [
        "Are you experiencing chest pain or pressure?",
        "Do you feel shortness of breath, especially while lying down or with light activity?",
        "Have you had palpitations or felt like your heart is racing?",
        "Have you felt dizzy or lightheaded recently?",
        "Have you fainted or nearly fainted recently?",
        "Have your ankles, legs, or abdomen become swollen more than usual?",
        "Have you had trouble sleeping due to breathing difficulty?",
        "Do you feel confused or disoriented?"
    ]

    var body: some View {
        NavigationStack {
            Form {
                Section(header: Text("Health Checkup").font(.headline)) {
                    ForEach(questions, id: \.self) { question in
                        Toggle(isOn: Binding(
                            get: { self.answers[question, default: false] },
                            set: { self.answers[question] = $0 }
                        )) {
                            Text(question)
                        }
                    }
                }

                Section {
                    Button("Submit") {
                        evaluateSymptoms()
                        showResult = true
                    }
                    .buttonStyle(.borderedProminent)
                    .frame(maxWidth: .infinity, alignment: .center)
                }
            }
            .navigationDestination(isPresented: $showResult) {
                SurveyResultView(recommendation: recommendation)
            }
        }
    }

    private func evaluateSymptoms() {
        let highRiskQuestions = [
            "Are you experiencing chest pain or pressure?",
            "Do you feel shortness of breath, especially while lying down or with light activity?",
            "Have you fainted or nearly fainted recently?"
        ]

        let moderateRiskQuestions = [
            "Have you had palpitations or felt like your heart is racing?",
            "Have you felt dizzy or lightheaded recently?",
            "Have your ankles, legs, or abdomen become swollen more than usual?",
            "Do you feel confused or disoriented?",
            "Have you had trouble sleeping due to breathing difficulty?",
            "Have you gained more than 5 lbs in the last week?"
        ]

        var score = 0

        for q in highRiskQuestions where answers[q] == true {
            score += 3
        }
        for q in moderateRiskQuestions where answers[q] == true {
            score += 1
        }

        if score >= 5 {
            recommendation = "⚠️ Seek emergency care immediately. Call 911 or go to the ER."
        } else if score >= 2 {
            recommendation = "📞 Contact your healthcare provider soon. You may need evaluation."
        } else {
            recommendation = "✅ No urgent symptoms detected. Continue monitoring and rest."
        }
    }
}



struct SurveyResultView: View {
    var recommendation: String

    var body: some View {
        VStack(spacing: 20) {
            Text("Survey Result")
                .font(.largeTitle)
                .bold()
                .padding()

            Text(recommendation)
                .font(.title2)
                .foregroundColor(.blue)
                .padding()

            Spacer()
        }
        .padding()
        .navigationTitle("Result")
    }
}

